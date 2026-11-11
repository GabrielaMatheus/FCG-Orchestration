param(
    [string]$SubscriptionId
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$repositoriesRoot = Split-Path $root -Parent
$documentsRoot = Split-Path $repositoriesRoot -Parent
$terraformDirectory = Join-Path $root 'infra\azure'

function Assert-LastExitCode([string]$Operation) {
    if ($LASTEXITCODE -ne 0) { throw "Falha durante: $Operation" }
}

function Resolve-Command([string]$Name, [string]$FallbackPath) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    if ($FallbackPath -and (Test-Path -LiteralPath $FallbackPath)) { return $FallbackPath }
    throw "O comando '$Name' nao esta instalado ou nao esta no PATH."
}

$terraformCommand = Resolve-Command 'terraform' (Join-Path $documentsRoot 'New project 3\.tools\terraform\terraform.exe')
$azureCliCommand = Resolve-Command 'az' (Join-Path $documentsRoot 'New project 3\.tools\azure-cli\bin\az.cmd')
$elasticApiKey = $null

Push-Location $root
try {
    & $azureCliCommand account show --only-show-errors | Out-Null
    Assert-LastExitCode 'confirmacao do login no Azure'

    if ($SubscriptionId) {
        & $azureCliCommand account set --subscription $SubscriptionId
        Assert-LastExitCode 'selecao da assinatura Azure'
    }

    Write-Host 'Cole a API key da organizacao Elastic Cloud. Nada aparecera na tela.' -ForegroundColor Cyan
    $secureElasticApiKey = Read-Host 'Elastic Cloud API key' -AsSecureString
    $elasticApiKey = [System.Net.NetworkCredential]::new('', $secureElasticApiKey).Password
    if ([string]::IsNullOrWhiteSpace($elasticApiKey)) { throw 'A API key do Elastic Cloud nao pode ficar vazia.' }
    $env:TF_VAR_elastic_cloud_api_key = $elasticApiKey

    Write-Host ''
    Write-Host 'ATENCAO: esta acao apaga toda a infraestrutura FCG e seus dados.' -ForegroundColor Yellow
    $confirmation = Read-Host 'Se as evidencias ja foram gravadas, digite exatamente DESTRUIR'
    if ($confirmation -cne 'DESTRUIR') {
        Write-Host 'Cancelado. Nada foi apagado.' -ForegroundColor Cyan
        return
    }

    & $terraformCommand "-chdir=$terraformDirectory" destroy
    Assert-LastExitCode 'terraform destroy'
    Write-Host 'Destruicao concluida. Confirme no Portal do Azure e no Elastic Cloud.' -ForegroundColor Green
}
finally {
    Remove-Item Env:TF_VAR_elastic_cloud_api_key -ErrorAction SilentlyContinue
    $elasticApiKey = $null
    Pop-Location
}
