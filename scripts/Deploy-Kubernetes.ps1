param([string]$Context='kind-fcg-fase3', [switch]$SkipImageLoad)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
function Check([string]$Operation) {if($LASTEXITCODE -ne 0){throw "Falha: $Operation"}}
function Require-EnvironmentVariable([string]$Name) {
    $value=[Environment]::GetEnvironmentVariable($Name)
    if([string]::IsNullOrWhiteSpace($value)){throw "Defina a variavel de ambiente $Name antes do deploy."}
    return $value
}
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
    $secret=@{
        apiVersion='v1';kind='Secret';metadata=@{name='fcg-runtime';namespace='fcg'};type='Opaque'
        stringData=@{
            Jwt__SecretKey=(Require-EnvironmentVariable 'JWT_SECRET')
            RabbitMq__Username=(Require-EnvironmentVariable 'RABBITMQ_USER')
            RabbitMq__Password=(Require-EnvironmentVariable 'RABBITMQ_PASSWORD')
            ADMIN_EMAIL=(Require-EnvironmentVariable 'ADMIN_EMAIL')
            ADMIN_PASSWORD=(Require-EnvironmentVariable 'ADMIN_PASSWORD')
            ConnectionStrings__UsersDatabase=(Require-EnvironmentVariable 'USERS_DATABASE')
            ConnectionStrings__CatalogDatabase=(Require-EnvironmentVariable 'CATALOG_DATABASE')
            ConnectionStrings__MongoDb=(Require-EnvironmentVariable 'MONGODB_CONNECTION')
            ConnectionStrings__Redis=(Require-EnvironmentVariable 'REDIS_CONNECTION')
            Elasticsearch__Uri=(Require-EnvironmentVariable 'ELASTICSEARCH_URI')
            Elasticsearch__Username=(Require-EnvironmentVariable 'ELASTICSEARCH_USERNAME')
            Elasticsearch__Password=(Require-EnvironmentVariable 'ELASTICSEARCH_PASSWORD')
            GrafanaPassword=(Require-EnvironmentVariable 'GRAFANA_PASSWORD')
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
    foreach($deployment in @('rabbitmq','mongodb','redis','opensearch','users-api','catalog-api','payments-api','kong','loki','prometheus','grafana')) {
        kubectl --context $Context -n fcg rollout status "deployment/$deployment" --timeout=180s
        Check "Deployment $deployment"
    }
    kubectl --context $Context -n fcg get pods
} finally {Pop-Location}
