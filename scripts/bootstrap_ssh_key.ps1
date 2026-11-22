$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$secretsDirectory = Join-Path $projectRoot '.secrets'
$privateKeyPath = Join-Path $secretsDirectory 'blackarch_lab_ed25519'
$authorizedKeysPath = Join-Path $projectRoot 'infrastructure\nginx\authorized_keys'

New-Item -ItemType Directory -Path $secretsDirectory -Force | Out-Null

if (-not (Test-Path -LiteralPath $privateKeyPath)) {
    & ssh-keygen -q -t ed25519 -N '' -C 'blackarch-security-lab' -f $privateKeyPath
    if ($LASTEXITCODE -ne 0) {
        throw 'ssh-keygen failed.'
    }
}

Copy-Item -LiteralPath "$privateKeyPath.pub" -Destination $authorizedKeysPath -Force
Write-Output "SSH private key: $privateKeyPath"
