param(
    [string]$BaseUrl = 'http://localhost:8000',
    [Parameter(Mandatory = $true)][string]$AdminEmail,
    [Parameter(Mandatory = $true)][string]$AdminPassword,
    [string]$TypoQuery = 'Avetura'
)

$ErrorActionPreference = 'Stop'

$loginBody = @{
    email = $AdminEmail
    password = $AdminPassword
} | ConvertTo-Json

$login = Invoke-RestMethod `
    -Method Post `
    -Uri "$BaseUrl/api/users/login" `
    -ContentType 'application/json' `
    -Body $loginBody

if ([string]::IsNullOrWhiteSpace($login.token)) {
    throw 'A UsersAPI nao retornou o token JWT esperado.'
}

$headers = @{ Authorization = "Bearer $($login.token)" }

$jwtProtection = $false
try {
    Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/api/games" | Out-Null
} catch {
    if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 401) {
        $jwtProtection = $true
    } else {
        throw
    }
}

if (-not $jwtProtection) {
    throw 'A rota protegida aceitou uma requisicao sem token JWT.'
}

$firstTimer = [Diagnostics.Stopwatch]::StartNew()
$firstResponse = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/api/games" -Headers $headers
$firstTimer.Stop()

$secondTimer = [Diagnostics.Stopwatch]::StartNew()
$secondResponse = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/api/games" -Headers $headers
$secondTimer.Stop()

$secondCacheStatus = [string]$secondResponse.Headers['X-Cache']
if ($secondCacheStatus -ne 'HIT') {
    throw "A segunda consulta deveria vir do Redis, mas X-Cache retornou '$secondCacheStatus'."
}

$games = $firstResponse.Content | ConvertFrom-Json
if (@($games).Count -eq 0) {
    throw 'O catalogo precisa ter ao menos um jogo para validar o MongoDB.'
}

$gameId = $games[0].id
Write-Host "Jogo usado na validacao MongoDB: $gameId"
$reviewComment = "Validacao Fase 4 - $([Guid]::NewGuid().ToString('N'))"
$reviewBody = @{
    rating = 5
    comment = $reviewComment
    metadata = @{
        origem = 'demonstracao-local'
        fase = '4'
    }
} | ConvertTo-Json

$createdReview = Invoke-RestMethod `
    -Method Post `
    -Uri "$BaseUrl/api/games/$gameId/reviews" `
    -Headers $headers `
    -ContentType 'application/json' `
    -Body $reviewBody

$reviews = @(Invoke-RestMethod -Uri "$BaseUrl/api/games/$gameId/reviews" -Headers $headers)
$mongoReviewFound = @($reviews | Where-Object { $_.id -eq $createdReview.id }).Count -eq 1
if (-not $mongoReviewFound) {
    throw 'A avaliacao criada nao foi encontrada no MongoDB.'
}

$encodedQuery = [Uri]::EscapeDataString($TypoQuery)
$searchResults = @(Invoke-RestMethod -Uri "$BaseUrl/search?q=$encodedQuery" -Headers $headers)
if ($searchResults.Count -eq 0) {
    throw "A busca fuzzy nao encontrou resultados para '$TypoQuery'."
}

for ($index = 1; $index -lt $searchResults.Count; $index++) {
    if ([double]$searchResults[$index].score -gt [double]$searchResults[$index - 1].score) {
        throw 'Os resultados da busca nao estao ordenados por relevancia decrescente.'
    }
}

[pscustomobject]@{
    CachePrimeMilliseconds = $firstTimer.ElapsedMilliseconds
    CacheHitMilliseconds   = $secondTimer.ElapsedMilliseconds
    SecondRequestCache     = $secondCacheStatus
    FuzzyQuery             = $TypoQuery
    SearchResults          = $searchResults.Count
    TopResult              = $searchResults[0].name
    TopScore               = $searchResults[0].score
    JwtProtection          = $jwtProtection
    MongoReviewPersisted   = $mongoReviewFound
    MongoReviewId          = $createdReview.id
} | Format-List

Write-Host 'Validacao Fase 4 concluida: JWT, cache Redis, busca fuzzy e MongoDB aprovados.' -ForegroundColor Green
