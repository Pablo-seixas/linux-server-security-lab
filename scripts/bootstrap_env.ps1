$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentPath = Join-Path $projectRoot '.env'

if (Test-Path -LiteralPath $environmentPath) {
    throw '.env already exists. Remove it explicitly before generating new credentials.'
}

function New-LabSecret {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    return [Convert]::ToHexString($bytes).ToLowerInvariant()
}

$ownerPassword = New-LabSecret
$applicationPassword = New-LabSecret

@"
APP_ENV=production
APP_PORT=8088
APP_BIND_ADDRESS=127.0.0.1
SSH_PORT=2222
POSTGRES_DB=security_lab
POSTGRES_OWNER=security_lab_owner
POSTGRES_OWNER_PASSWORD=$ownerPassword
POSTGRES_APP_USER=security_lab_app
POSTGRES_APP_PASSWORD=$applicationPassword
"@ | Set-Content -LiteralPath $environmentPath -Encoding utf8NoBOM

Write-Output 'Created .env with randomly generated local lab credentials.'

$secretsDirectory = Join-Path $projectRoot '.secrets'
$privateKeyPath = Join-Path $secretsDirectory 'blackarch_lab_ed25519'
New-Item -ItemType Directory -Path $secretsDirectory -Force | Out-Null

if (-not (Test-Path -LiteralPath $privateKeyPath)) {
    & ssh-keygen -q -t ed25519 -N '' -C 'blackarch-security-lab' -f $privateKeyPath
}

Copy-Item -LiteralPath "$privateKeyPath.pub" -Destination (
    Join-Path $PSScriptRoot '..\infrastructure\nginx\authorized_keys'
) -Force
Write-Output 'Created the isolated lab SSH key pair.'
