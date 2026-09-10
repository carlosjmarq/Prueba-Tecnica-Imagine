$ErrorActionPreference = "Stop"

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Package = Join-Path $Here "package"
$BuildDir = Join-Path $Here "_build"
$ZipPath = Join-Path $BuildDir "lambda.zip"

if (Test-Path $Package) {
    Remove-Item -Recurse -Force $Package
}
New-Item -ItemType Directory -Path $Package | Out-Null
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

Copy-Item (Join-Path $Here "lambda_function.py") $Package

python -m pip install --disable-pip-version-check --no-cache-dir `
    -r (Join-Path $Here "requirements.txt") `
    --target $Package

if (Test-Path $ZipPath) {
    Remove-Item -Force $ZipPath
}
Compress-Archive -Path (Join-Path $Package "*") -DestinationPath $ZipPath -Force

Write-Host "Lambda package listo: $ZipPath"
