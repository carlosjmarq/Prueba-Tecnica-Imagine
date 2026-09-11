# seed.ps1 - Aplica la migracion de datos (mock) bajo demanda en dev o produccion.
# El seed es una migracion Alembic idempotente (backend/alembic/versions/*_seed_mock_data.py):
#   - dev:  corre contra la BD local (DATABASE_URL de backend/.env -> :5434).
#   - prod: corre via SSM Run Command en la instancia desplegada (mismo mecanismo
#           que `deploy-aws.ps1 migrate`, pero de forma explicita y on-demand).
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File scripts/seed.ps1                # dev
#   powershell -ExecutionPolicy Bypass -File scripts/seed.ps1 -Env dev
#   powershell -ExecutionPolicy Bypass -File scripts/seed.ps1 -Env prod      # pide confirmacion
#   powershell -ExecutionPolicy Bypass -File scripts/seed.ps1 -Env prod -Force
#   powershell -ExecutionPolicy Bypass -File scripts/seed.ps1 -Env prod -Environment dev -Region eu-west-1
#
# Notas:
#   - En prod debe estar desplegada la imagen que incluya la migracion de seed
#     (el CD reconstruye la imagen al tocar backend/**).
#   - Es idempotente: si ya se aplico, no duplica datos.

param(
    [ValidateSet("dev", "prod")]
    [string]$Env = "dev",
    [string]$Environment = "dev",
    [string]$Region = "eu-west-1",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "backend"

function Write-Step([string]$Msg) { Write-Host "`n== $Msg ==" -ForegroundColor Cyan }
function Write-Ok([string]$Msg) { Write-Host "  [ok] $Msg" -ForegroundColor Green }

# ------------------------------------------------------------------ dev
if ($Env -eq "dev") {
    if (-not (Test-Path (Join-Path $backend "pyproject.toml"))) {
        Write-Error "Backend no inicializado (uv sync)."
        exit 1
    }
    Write-Step "seed (dev) - alembic upgrade head en BD local"
    Push-Location $backend
    try {
        uv run alembic upgrade head
        if ($LASTEXITCODE -ne 0) { throw "alembic upgrade head fallo (BD local levantada? -> scripts/dev.ps1)" }
    }
    finally {
        Pop-Location
    }
    Write-Ok "Mock data sembrado en la BD local."
    exit 0
}

# ------------------------------------------------------------------ prod
if (-not $Force) {
    $answer = Read-Host "Sembrar mock data en el entorno AWS '$Environment'? [y/N]"
    if ($answer -notmatch "^(y|Y)$") {
        Write-Host "Cancelado."
        exit 0
    }
}

$asgName = "delivery-$Environment-api-asg"
Write-Step "seed (prod) - alembic upgrade head via SSM (ASG $asgName, $Region)"

$instanceId = aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names $asgName `
    --region $Region `
    --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId | [0]" `
    --output text 2>$null
if ($LASTEXITCODE -ne 0 -or -not $instanceId -or $instanceId -eq "None") {
    Write-Error "No hay instancia InService en $asgName"
    exit 1
}

$params = @{ commands = @("docker exec api alembic upgrade head") } | ConvertTo-Json -Compress
$paramsFile = Join-Path $env:TEMP "ssm-seed.json"
Set-Content -Path $paramsFile -Value $params -NoNewline -Encoding ascii

$cmdId = aws ssm send-command --instance-ids $instanceId `
    --document-name "AWS-RunShellScript" `
    --parameters "file://$paramsFile" `
    --region $Region `
    --query "Command.CommandId" --output text
if ($LASTEXITCODE -ne 0) { throw "No se pudo lanzar el comando SSM" }
Write-Host "  -> comando SSM $cmdId lanzado, esperando..." -ForegroundColor DarkGray

for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 10
    $inv = aws ssm get-command-invocation --command-id $cmdId --instance-id $instanceId `
        --region $Region `
        --query "{Status:Status,Out:StandardOutputContent,Err:StandardErrorContent}" `
        --output json 2>$null
    if ($LASTEXITCODE -ne 0) { continue }
    $invObj = $inv | ConvertFrom-Json
    if ($invObj.Status -eq "Success") {
        Write-Host $invObj.Out -ForegroundColor Gray
        Write-Ok "Mock data sembrado en el entorno AWS '$Environment'."
        exit 0
    }
    if ($invObj.Status -in @("Failed", "Cancelled", "TimedOut")) {
        Write-Host $invObj.Err -ForegroundColor Red
        Write-Error "Comando SSM termino con estado $($invObj.Status)"
        exit 1
    }
}
Write-Error "Comando SSM agoto el timeout."
exit 1