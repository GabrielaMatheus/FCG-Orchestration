param(
    [string]$SubscriptionId,
    [string]$AdminEmail,
    [switch]$PlanOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$repositoriesRoot = Split-Path $root -Parent
$documentsRoot = Split-Path $repositoriesRoot -Parent
$terraformDirectory = Join-Path $root 'infra\azure'
$terraformVariablesPath = Join-Path $terraformDirectory 'terraform.tfvars'
$terraformPlanPath = Join-Path $terraformDirectory 'fase4.tfplan'

function Assert-LastExitCode([string]$Operation) {
    if ($LASTEXITCODE -ne 0) { throw "Falha durante: $Operation" }
}

function Resolve-Command([string]$Name, [string]$FallbackPath) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    if ($FallbackPath -and (Test-Path -LiteralPath $FallbackPath)) { return $FallbackPath }
    throw "O comando '$Name' nao esta instalado ou nao esta no PATH."
}

function ConvertFrom-SecureValue([Security.SecureString]$SecureValue) {
    return [System.Net.NetworkCredential]::new('', $SecureValue).Password
}

function Assert-SafeTerraformString([string]$Value, [string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Value)) { throw "$Name nao pode ficar vazio." }
    if ($Value.Contains('"') -or $Value.Contains("`r") -or $Value.Contains("`n")) {
        throw "$Name contem um caractere que nao e aceito pelo assistente."
    }
}

$terraformCommand = Resolve-Command 'terraform' (Join-Path $documentsRoot 'New project 3\.tools\terraform\terraform.exe')
$azureCliCommand = Resolve-Command 'az' (Join-Path $documentsRoot 'New project 3\.tools\azure-cli\bin\az.cmd')
$elasticApiKey = $null

Push-Location $root
try {
    & $azureCliCommand account show --only-show-errors | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'O navegador sera aberto para voce entrar na sua conta Microsoft.' -ForegroundColor Cyan
        & $azureCliCommand login --only-show-errors
        Assert-LastExitCode 'login no Azure'
    }

    if (-not $SubscriptionId) {
        $SubscriptionId = (& $azureCliCommand account show --query id --output tsv --only-show-errors).Trim()
        Assert-LastExitCode 'leitura da assinatura Azure atual'
    }
    Assert-SafeTerraformString $SubscriptionId 'O ID da assinatura Azure'

    & $azureCliCommand account set --subscription $SubscriptionId
    Assert-LastExitCode 'selecao da assinatura Azure'

    if (-not $AdminEmail) {
        $AdminEmail = Read-Host 'Digite o e-mail que sera o administrador do FCG'
    }
    Assert-SafeTerraformString $AdminEmail 'O e-mail do administrador'
    if ($AdminEmail -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
        throw 'O e-mail informado nao parece valido.'
    }

    Write-Host ''
    Write-Host 'Agora cole a API key da sua organizacao Elastic Cloud.' -ForegroundColor Cyan
    Write-Host 'Os caracteres nao aparecerao na tela e a chave nao sera gravada no terraform.tfvars.'
    $secureElasticApiKey = Read-Host 'Elastic Cloud API key' -AsSecureString
    $elasticApiKey = ConvertFrom-SecureValue $secureElasticApiKey
    if ([string]::IsNullOrWhiteSpace($elasticApiKey)) { throw 'A API key do Elastic Cloud nao pode ficar vazia.' }
    $env:TF_VAR_elastic_cloud_api_key = $elasticApiKey

    $terraformVariables = @(
        "azure_subscription_id = `"$SubscriptionId`""
        'location              = "East US 2"'
        'cluster_name          = "fcg-prod-aks"'
        "admin_email          = `"$AdminEmail`""
        ''
        '# Azure permite somente uma conta Cosmos DB Free Tier por assinatura.'
        'cosmos_enable_free_tier = true'
        ''
        '# Ambiente academico pequeno. Revise os custos antes de aplicar.'
        'node_count                       = 2'
        'redis_high_availability_enabled = false'
    )
    [IO.File]::WriteAllLines($terraformVariablesPath, $terraformVariables, [Text.UTF8Encoding]::new($false))

    & $terraformCommand "-chdir=$terraformDirectory" init
    Assert-LastExitCode 'terraform init'
    & $terraformCommand "-chdir=$terraformDirectory" fmt -check
    Assert-LastExitCode 'terraform fmt -check'
    & $terraformCommand "-chdir=$terraformDirectory" validate
    Assert-LastExitCode 'terraform validate'
    & $terraformCommand "-chdir=$terraformDirectory" plan -out $terraformPlanPath
    Assert-LastExitCode 'terraform plan'

    if ($PlanOnly) {
        Write-Host ''
        Write-Host 'Plano pronto. Nenhum recurso foi criado.' -ForegroundColor Green
        return
    }

    Write-Host ''
    Write-Host 'ATENCAO: o proximo passo cria recursos pagos no Azure e no Elastic Cloud.' -ForegroundColor Yellow
    Write-Host 'Leia o resumo do plano acima. Um Budget do Azure apenas avisa; ele nao bloqueia gastos.' -ForegroundColor Yellow
    $confirmation = Read-Host 'Se deseja criar os recursos, digite exatamente APLICAR'
    if ($confirmation -cne 'APLICAR') {
        Write-Host 'Cancelado com seguranca. Nenhum recurso foi criado.' -ForegroundColor Cyan
        return
    }

    & $terraformCommand "-chdir=$terraformDirectory" apply $terraformPlanPath
    Assert-LastExitCode 'terraform apply'

    Write-Host ''
    Write-Host 'Infraestrutura criada. O proximo comando e:' -ForegroundColor Green
    Write-Host 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Deploy-Azure.ps1'
}
finally {
    Remove-Item Env:TF_VAR_elastic_cloud_api_key -ErrorAction SilentlyContinue
    $elasticApiKey = $null
    Pop-Location
}
