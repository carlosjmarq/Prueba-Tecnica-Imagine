# dev.ps1 - Levanta todo el proyecto para desarrollo
# 1. Arranca infra (Postgres + MinIO) via docker compose
# 2. Aplica migraciones Alembic si faltan
# 3. Arranca la API FastAPI (uvicorn) en foreground
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File scripts/dev.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/dev.ps1 -Reload   # hot reload
#   powershell -ExecutionPolicy Bypass -File scripts/dev.ps1 -Stop     # detiene todo

param(
    [switch]$Reload,
    [switch]$Stop,
    [int]$Port = 8000
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
$compose = Join-Path $root "infra\docker-compose.base.yml"
$backend = Join-Path $root "backend"

# ---------------------------------------------------------------- Stop
if ($Stop) {
    Write-Host "== Deteniendo servicios ==" -ForegroundColor Cyan
    $p = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($p) {
        Stop-Process -Id $p.OwningProcess -Force -ErrorAction SilentlyContinue
        Write-Host "API (puerto $Port) detenida."
    } else {
        Write-Host "API no estaba corriendo."
    }
    docker compose -f $compose down
    exit 0
}

# ---------------------------------------------------------------- Pre-checks
if (-not (Test-Path $compose)) { Write-Error "No existe $compose"; exit 1 }
if (-not (Test-Path (Join-Path $backend "pyproject.toml"))) { Write-Error "Backend no inicializado (uv sync)"; exit 1 }

Write-Host "== 1/3 Infra (Postgres + MinIO) ==" -ForegroundColor Cyan
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Docker daemon no esta corriendo. Abriendo Docker Desktop..."
    $dd = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dd) { Start-Process $dd }
    $ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep 5
        docker info *> $null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    }
    if (-not $ready) { Write-Error "Docker no arranco a tiempo."; exit 1 }
}

docker compose -f $compose up -d 2>&1 | Select-Object -Last 2
Start-Sleep 6
docker compose -f $compose ps --format "table {{.Name}}\t{{.Status}}" | Select-String "imagine"

# ---------------------------------------------------------------- Backend env + deps
Write-Host "`n== 2/3 Backend (deps + migraciones) ==" -ForegroundColor Cyan
if (-not (Test-Path (Join-Path $backend ".env"))) {
    Copy-Item (Join-Path $backend ".env.example") (Join-Path $backend ".env")
    Write-Host "  .env creado desde .env.example"
}

Push-Location $backend
try {
    uv sync --group dev 2>&1 | Select-Object -Last 1
    uv run alembic upgrade head 2>&1 | Select-Object -Last 1
} finally {
    Pop-Location
}

# ---------------------------------------------------------------- API
Write-Host "`n== 3/3 Arrancando API en http://127.0.0.1:$Port ==" -ForegroundColor Cyan
Write-Host "  Swagger: http://127.0.0.1:$Port/docs"
Write-Host "  (Ctrl+C para detener la API; Postgres/MinIO siguen arriba)"
Write-Host ""

Push-Location $backend
try {
    if ($Reload) {
        uv run uvicorn app.main:app --host 127.0.0.1 --port $Port --reload
    } else {
        uv run uvicorn app.main:app --host 127.0.0.1 --port $Port
    }
} finally {
    Pop-Location
}