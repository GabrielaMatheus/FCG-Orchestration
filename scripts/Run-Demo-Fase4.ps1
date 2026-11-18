param(
    [string]$BaseUrl = 'http://localhost:8000',
    [string]$AdminEmail = 'admin@fiap.local'
)

$ErrorActionPreference = 'Stop'
$securePassword = Read-Host 'Digite a senha local de demonstracao' -AsSecureString
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)

try {
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    & "$PSScriptRoot/Test-Fase4.ps1" `
        -BaseUrl $BaseUrl `
        -AdminEmail $AdminEmail `
        -AdminPassword $plainPassword
} finally {
    if ($passwordPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
    $plainPassword = $null
}
