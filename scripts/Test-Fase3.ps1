param([string]$BaseUrl='http://localhost:8000', [string]$PrometheusUrl='http://localhost:9090', [string]$LokiUrl='http://localhost:3100', [string]$GrafanaUrl='http://localhost:3000', [ValidateSet('Compose','Kubernetes')][string]$CacheMode='Compose')
$ErrorActionPreference='Stop'
function Assert($Condition,[string]$Message) {
    if (-not $Condition) { throw $Message }
    Write-Host "OK - $Message" -ForegroundColor Green
}
foreach ($path in @('/api/games','/api/users/me','/api/users')) {
    try {
        Invoke-RestMethod "$BaseUrl$path" | Out-Null
        throw "Rota $path aceitou chamada sem token."
    } catch {
        if (-not $_.Exception.Response) { throw }
        Assert ([int]$_.Exception.Response.StatusCode -eq 401) "Gateway bloqueia $path sem JWT"
    }
}
$email='fase3.'+[Guid]::NewGuid().ToString('N')+'@example.com'
$password='TesteFase3@123!'
$body=@{name='Validacao Fase 3';email=$email;password=$password}|ConvertTo-Json
$user=Invoke-RestMethod "$BaseUrl/api/users" -Method Post -ContentType application/json -Body $body
Assert ($null -ne $user.id) 'Cadastro pelo Gateway'
$body=@{email=$email;password=$password}|ConvertTo-Json
$login=Invoke-RestMethod "$BaseUrl/api/users/login" -Method Post -ContentType application/json -Body $body
$headers=@{Authorization="Bearer $($login.token)"}
$me=Invoke-RestMethod "$BaseUrl/api/users/me" -Headers $headers
Assert ($me.id -eq $user.id) 'Login e consulta autenticada'
$games=Invoke-RestMethod "$BaseUrl/api/games" -Headers $headers
Assert ($games.Count -gt 0) 'Catalogo disponivel'
$gameId=$games[0].id
1..5|ForEach-Object { Invoke-RestMethod "$BaseUrl/api/games" -Headers $headers | Out-Null }
if($CacheMode -eq 'Compose') {
    $cached=docker compose -f "$PSScriptRoot/../docker-compose.yml" exec -T redis redis-cli HGET fcg-catalog:games:list data
    if($LASTEXITCODE -ne 0){throw 'Falha ao consultar Redis no Compose.'}
} else {
    $cached=kubectl --context kind-fcg-fase3 -n fcg exec deployment/redis -- redis-cli HGET fcg-catalog:games:list data
    if($LASTEXITCODE -ne 0){throw 'Falha ao consultar Redis no Kubernetes.'}
}
Assert ($cached -match [regex]::Escape([string]$gameId)) 'Resultado da consulta armazenado no Redis'
$body=@{rating=5;comment='Validacao integrada Fase 3';metadata=@{origem='teste-integrado';usuario=$email}}|ConvertTo-Json
$review=Invoke-RestMethod "$BaseUrl/api/games/$gameId/reviews" -Method Post -Headers $headers -ContentType application/json -Body $body
$reviews=Invoke-RestMethod "$BaseUrl/api/games/$gameId/reviews" -Headers $headers
Assert (@($reviews|Where-Object id -eq $review.id).Count -eq 1) 'Avaliacao gravada e consultada no MongoDB'
$order=Invoke-RestMethod "$BaseUrl/api/users/$($user.id)/games/$gameId/purchase" -Method Post -Headers $headers
Assert ($order.status -eq 'Pending') 'Compra aceita para processamento assincrono'
$completed=$false
for($i=0;$i -lt 30;$i++) {
    $library=Invoke-RestMethod "$BaseUrl/api/users/$($user.id)/library" -Headers $headers
    if(@($library|Where-Object id -eq $gameId).Count -gt 0) {$completed=$true;break}
    Start-Sleep -Seconds 1
}
Assert $completed 'Pagamento aprovado e jogo adicionado a biblioteca'
$foundLogs=$false
$query=[uri]::EscapeDataString('{service="notifications-function"} |= "'+$email+'"')
for($i=0;$i -lt 30;$i++) {
    $logs=Invoke-RestMethod "$LokiUrl/loki/api/v1/query_range?query=$query&limit=100"
    $types=@($logs.data.result|ForEach-Object {$_.stream.type})
    if($types -contains 'Welcome' -and $types -contains 'PurchaseConfirmation') {$foundLogs=$true;break}
    Start-Sleep -Seconds 1
}
Assert $foundLogs 'Function: boas-vindas e confirmacao de compra no Loki'
$targets=(Invoke-RestMethod "$PrometheusUrl/api/v1/targets").data.activeTargets
foreach($job in @('users-api','catalog-api','kong')) {
    Assert (@($targets|Where-Object {$_.labels.job -eq $job -and $_.health -eq 'up'}).Count -gt 0) "Prometheus coleta $job"
}
$metric=[uri]::EscapeDataString('sum(http_requests_received_total) by (job,code)')
Assert ((Invoke-RestMethod "$PrometheusUrl/api/v1/query?query=$metric").data.result.Count -gt 0) 'Metricas por codigo HTTP disponiveis'
Assert ((Invoke-RestMethod "$GrafanaUrl/api/health").database -eq 'ok') 'Grafana disponivel'
Write-Host "Teste integrado concluido. Conta de demonstracao: $email"
