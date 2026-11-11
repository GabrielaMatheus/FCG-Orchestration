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

$firstTimer = [Diagnostics.Stopwatch]::StartNew()
$firstResponse = Invoke-WebRequest -Uri "$BaseUrl/api/games" -Headers $headers
$firstTimer.Stop()

$secondTimer = [Diagnostics.Stopwatch]::StartNew()
$secondResponse = Invoke-WebRequest -Uri "$BaseUrl/api/games" -Headers $headers
$secondTimer.Stop()

$secondCacheStatus = [string]$secondResponse.Headers['X-Cache']
if ($secondCacheStatus -ne 'HIT') {
    throw "A segunda consulta deveria vir do Redis, mas X-Cache retornou '$secondCacheStatus'."
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
} | Format-List

Write-Host 'Validacao Fase 4 concluida: cache HIT e busca fuzzy ordenada por relevancia.' -ForegroundColor Green
