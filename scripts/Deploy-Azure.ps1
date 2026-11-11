param(
    [string]$ResourceGroup,
    [string]$ClusterName,
    [string]$KeyVaultName,
    [string]$AcrName,
    [string]$AcrLoginServer,
    [string]$CsiClientId,
    [string]$TenantId,
    [switch]$SkipImageBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$repositoriesRoot = Split-Path $root -Parent
$documentsRoot = Split-Path $repositoriesRoot -Parent
$terraformDirectory = Join-Path $root 'infra\azure'
$temporarySecretFile = Join-Path ([IO.Path]::GetTempPath()) ("fcg-runtime-{0}.env" -f [guid]::NewGuid())
$temporaryCsiFile = Join-Path ([IO.Path]::GetTempPath()) ("fcg-csi-{0}.yaml" -f [guid]::NewGuid())

function Assert-LastExitCode([string]$Operation) {
    if ($LASTEXITCODE -ne 0) { throw "Falha durante: $Operation" }
}

function Resolve-Command([string]$Name, [string]$FallbackPath) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    if ($FallbackPath -and (Test-Path -LiteralPath $FallbackPath)) { return $FallbackPath }
    throw "O comando '$Name' nao esta instalado ou nao esta no PATH."
}

function Get-TerraformOutput([string]$Name) {
    $value = & $script:TerraformCommand "-chdir=$terraformDirectory" output -raw $Name
    Assert-LastExitCode "leitura do output Terraform $Name"
    return ([string]$value).Trim()
}

function Get-KeyVaultSecret([string]$SecretName) {
    $value = & $script:AzureCliCommand keyvault secret show `
        --vault-name $KeyVaultName `
        --name $SecretName `
        --query value `
        --output tsv `
        --only-show-errors
    Assert-LastExitCode "leitura do segredo $SecretName no Azure Key Vault"
    return [string]$value
}

$script:TerraformCommand = Resolve-Command 'terraform' (Join-Path $documentsRoot 'New project 3\.tools\terraform\terraform.exe')
$script:AzureCliCommand = Resolve-Command 'az' (Join-Path $documentsRoot 'New project 3\.tools\azure-cli\bin\az.cmd')
$null = Resolve-Command 'kubectl' ''

if (-not $ResourceGroup) { $ResourceGroup = Get-TerraformOutput 'resource_group_name' }
if (-not $ClusterName) { $ClusterName = Get-TerraformOutput 'cluster_name' }
if (-not $KeyVaultName) { $KeyVaultName = Get-TerraformOutput 'key_vault_name' }
if (-not $AcrName) { $AcrName = Get-TerraformOutput 'acr_name' }
if (-not $AcrLoginServer) { $AcrLoginServer = Get-TerraformOutput 'acr_login_server' }
if (-not $CsiClientId) { $CsiClientId = Get-TerraformOutput 'key_vault_csi_client_id' }
if (-not $TenantId) { $TenantId = Get-TerraformOutput 'azure_tenant_id' }

$secretMap = [ordered]@{
    'Jwt__SecretKey'                     = 'jwt-secret-key'
    'RabbitMq__Username'                 = 'rabbitmq-username'
    'RabbitMq__Password'                 = 'rabbitmq-password'
    'ADMIN_EMAIL'                        = 'admin-email'
    'ADMIN_PASSWORD'                     = 'admin-password'
    'ConnectionStrings__UsersDatabase'   = 'users-database'
    'ConnectionStrings__CatalogDatabase' = 'catalog-database'
    'ConnectionStrings__MongoDb'         = 'mongodb-connection'
    'ConnectionStrings__Redis'           = 'redis-connection'
    'Elasticsearch__Uri'                 = 'elasticsearch-uri'
    'Elasticsearch__Username'            = 'elasticsearch-username'
    'Elasticsearch__Password'            = 'elasticsearch-password'
    'GrafanaPassword'                    = 'grafana-password'
}

Push-Location $root
try {
    & $script:AzureCliCommand account show --only-show-errors | Out-Null
    Assert-LastExitCode 'confirmacao do login no Azure'

    & $script:AzureCliCommand aks get-credentials `
        --resource-group $ResourceGroup `
        --name $ClusterName `
        --admin `
        --overwrite-existing `
        --only-show-errors
    Assert-LastExitCode 'configuracao do contexto AKS'

    if (-not $SkipImageBuild) {
        $null = Resolve-Command 'docker' ''
        & $script:AzureCliCommand acr login --name $AcrName --only-show-errors
        Assert-LastExitCode 'login no Azure Container Registry'

        $images = @(
            @{ Name = 'fcg-users-api'; Context = Join-Path $repositoriesRoot 'FCG-UsersAPI' },
            @{ Name = 'fcg-catalog-api'; Context = Join-Path $repositoriesRoot 'FCG-CatalogAPI' },
            @{ Name = 'fcg-payments-api'; Context = Join-Path $repositoriesRoot 'FCG-PaymentsAPI' }
        )

        foreach ($image in $images) {
            $tag = "$AcrLoginServer/$($image.Name):latest"
            docker build --tag $tag $image.Context
            Assert-LastExitCode "build da imagem $($image.Name)"
            docker push $tag
            Assert-LastExitCode "push da imagem $($image.Name)"
        }
    }

    $secretLines = foreach ($entry in $secretMap.GetEnumerator()) {
        $value = Get-KeyVaultSecret $entry.Value
        if ($value.Contains("`r") -or $value.Contains("`n")) {
            throw "O segredo $($entry.Value) contem quebra de linha e nao pode ser importado como env-file."
        }
        "$($entry.Key)=$value"
    }
    [IO.File]::WriteAllLines($temporarySecretFile, $secretLines, [Text.UTF8Encoding]::new($false))

    kubectl apply -f k8s/base/namespace.yaml
    Assert-LastExitCode 'criacao do namespace'

    $secretManifest = kubectl --namespace fcg create secret generic fcg-runtime `
        --from-env-file $temporarySecretFile `
        --dry-run=client `
        -o yaml
    Assert-LastExitCode 'geracao do Secret do Kubernetes'
    $secretManifest | kubectl apply -f -
    Assert-LastExitCode 'sincronizacao inicial do Azure Key Vault para o Kubernetes Secret'

    $csiTemplatePath = Join-Path $root 'k8s\overlays\azure\secret-provider-class.template.yaml'
    $csiManifest = Get-Content -LiteralPath $csiTemplatePath -Raw
    $csiManifest = $csiManifest.Replace('__CSI_CLIENT_ID__', $CsiClientId)
    $csiManifest = $csiManifest.Replace('__KEY_VAULT_NAME__', $KeyVaultName)
    $csiManifest = $csiManifest.Replace('__TENANT_ID__', $TenantId)
    [IO.File]::WriteAllText($temporaryCsiFile, $csiManifest, [Text.UTF8Encoding]::new($false))
    kubectl apply -f $temporaryCsiFile
    Assert-LastExitCode 'integracao do Key Vault com o Secrets Store CSI Driver'

    kubectl apply -k k8s/overlays/azure
    Assert-LastExitCode 'aplicacao dos manifestos de producao no AKS'

    kubectl --namespace fcg set image deployment/users-api users-api="$AcrLoginServer/fcg-users-api:latest"
    Assert-LastExitCode 'configuracao da imagem da UsersAPI'
    kubectl --namespace fcg set image deployment/catalog-api catalog-api="$AcrLoginServer/fcg-catalog-api:latest"
    Assert-LastExitCode 'configuracao da imagem da CatalogAPI'
    kubectl --namespace fcg set image deployment/payments-api payments-api="$AcrLoginServer/fcg-payments-api:latest"
    Assert-LastExitCode 'configuracao da imagem da PaymentsAPI'

    foreach ($deployment in @('key-vault-sync', 'rabbitmq', 'users-api', 'catalog-api', 'payments-api', 'kong')) {
        kubectl --namespace fcg rollout status "deployment/$deployment" --timeout=10m
        Assert-LastExitCode "rolling update de $deployment"
    }

    kubectl --namespace fcg get pods
    kubectl --namespace fcg get service kong
}
finally {
    Pop-Location
    foreach ($temporaryFile in @($temporarySecretFile, $temporaryCsiFile)) {
        if (Test-Path -LiteralPath $temporaryFile) {
            Remove-Item -LiteralPath $temporaryFile -Force
        }
    }
}
