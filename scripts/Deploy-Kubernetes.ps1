param([string]$Context='kind-fcg-fase3', [switch]$SkipImageLoad)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
function Check([string]$Operation) {if($LASTEXITCODE -ne 0){throw "Falha: $Operation"}}
Push-Location $root
try {
    kubectl --context $Context cluster-info | Out-Null
    Check 'acesso ao cluster'
    if(-not $SkipImageLoad) {
        docker compose build
        Check 'build das imagens'
        kind load docker-image fcg-orchestration-users-api:latest fcg-orchestration-catalog-api:latest fcg-orchestration-payments-api:latest --name fcg-fase3
        Check 'carregamento das imagens no kind'
    }
    kubectl --context $Context apply -f k8s/namespace.yaml
    Check 'namespace'
    # Credenciais exclusivas do ambiente local de demonstracao.
    $jwt=if($env:JWT_SECRET){$env:JWT_SECRET}else{'development-only-secret-key-change-me-123456789'}
    $adminPassword=if($env:ADMIN_PASSWORD){$env:ADMIN_PASSWORD}else{'Admin@123!'}
    $secret=@{
        apiVersion='v1';kind='Secret';metadata=@{name='fcg-runtime';namespace='fcg'};type='Opaque'
        stringData=@{
            Jwt__SecretKey=$jwt;RabbitMq__Password='guest';ADMIN_EMAIL='admin@fiap.com.br';ADMIN_PASSWORD=$adminPassword
            ConnectionStrings__UsersDatabase='Data Source=/data/users.db'
            ConnectionStrings__CatalogDatabase='Data Source=/data/catalog.db'
            ConnectionStrings__MongoDb='mongodb://mongodb:27017'
            GrafanaPassword='admin'
        }
    }
    $secret|ConvertTo-Json -Depth 8|kubectl --context $Context apply -f -
    Check 'Secrets'
    kubectl --context $Context apply -k .
    Check 'manifestos'
    if(-not $SkipImageLoad) {
        kubectl --context $Context -n fcg rollout restart deployment/users-api deployment/catalog-api deployment/payments-api
        Check 'atualizacao das imagens dos microsservicos'
    }
    foreach($deployment in @('rabbitmq','mongodb','redis','users-api','catalog-api','payments-api','kong','loki','prometheus','grafana')) {
        kubectl --context $Context -n fcg rollout status "deployment/$deployment" --timeout=180s
        Check "Deployment $deployment"
    }
    kubectl --context $Context -n fcg get pods
} finally {Pop-Location}
