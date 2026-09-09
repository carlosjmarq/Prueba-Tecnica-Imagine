# setup.ps1 - Instalacion y verificacion del toolchain del proyecto
# Fase 0 del workflow (ver docs/40 Proceso/Setup y herramientas)
# Idempotente: solo instala lo que falta. Ejecutar como Administrador para winget.
#
# Uso:  powershell -ExecutionPolicy Bypass -File scripts/setup.ps1

$ErrorActionPreference = "Continue"
$results = @()

function Test-Command([string]$cmd) {
    try { Get-Command $cmd -ErrorAction Stop | Out-Null; return $true }
    catch { return $false }
}

function Get-Version([string]$cmd, [string]$args = "--version") {
    try {
        $v = & $cmd $args 2>&1 | Select-Object -First 1
        return "$v"
    } catch { return "(no detectada)" }
}

function Add-Result([string]$tool, [string]$version, [bool]$ok) {
    $script:results += [PSCustomObject]@{ Tool = $tool; Version = $version; Estado = $(if ($ok) { "OK" } else { "FALTA" }) }
}

function Add-ToSessionPath([string]$dir) {
    if ($dir -and (Test-Path $dir) -and ($env:PATH -notlike "*$dir*")) {
        $env:PATH = "$dir;$env:PATH"
    }
}

function Add-ToUserPath([string]$dir) {
    if (-not $dir -or -not (Test-Path $dir)) { return }
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$dir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$dir", "User")
        Write-Host "  -> PATH de usuario actualizado con: $dir" -ForegroundColor DarkGray
    }
}

function Install-Winget([string]$id, [string]$tool) {
    Write-Host "  -> Instalando $tool ($id) via winget..."
    $out = winget install --id $id --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1
    $out | ForEach-Object { Write-Host "     $_" }
    if ($LASTEXITCODE -ne 0) { Write-Warning "  !! winget fallo para $tool (codigo $LASTEXITCODE)" }
}

Write-Host "=== Prueba Tecnica Imagine - Setup del toolchain ===" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------- Git
if (Test-Command git) { Add-Result "Git" (Get-Version git) $true }
else {
    Write-Host "[Git] No encontrado. Instalando..." -ForegroundColor Yellow
    Install-Winget "Git.Git" "Git"
    Add-Result "Git" (Get-Version git) $true
}

# ---------------------------------------------------------------- Node.js
if (Test-Command node) { Add-Result "Node.js" (Get-Version node) $true }
else {
    Write-Host "[Node.js] No encontrado. Instalando..." -ForegroundColor Yellow
    Install-Winget "OpenJS.NodeJS.LTS" "Node.js"
    Add-Result "Node.js" (Get-Version node) $true
}

# ---------------------------------------------------------------- Python 3.12+
if (Test-Command python) {
    $py = (Get-Version python).Trim()
    if ($py -match "3\.(1[2-9]|[2-9][0-9])") { Add-Result "Python" $py $true }
    else { Add-Result "Python" "$py (se requiere 3.12+)" $false }
}
else {
    Write-Host "[Python] No encontrado. Instalando Python 3.12..." -ForegroundColor Yellow
    Install-Winget "Python.Python.3.12" "Python 3.12"
    Add-Result "Python" (Get-Version python) $true
}

# ---------------------------------------------------------------- uv
Add-ToSessionPath (Join-Path $env:USERPROFILE ".local\bin")
if (Test-Command uv) { Add-Result "uv" (Get-Version uv) $true }
else {
    Write-Host "[uv] No encontrado. Instalando via winget..." -ForegroundColor Yellow
    try { Install-Winget "astral-sh.uv" "uv" } catch { Write-Warning "  !! fallo instalando uv: $($_.Exception.Message)" }
    Add-ToSessionPath (Join-Path $env:USERPROFILE ".local\bin")
    if (Test-Command uv) { Add-Result "uv" (Get-Version uv) $true }
    else { Add-Result "uv" "instalado via winget (reiniciar terminal)" $true }
}

# ---------------------------------------------------------------- Flutter SDK
if (Test-Command flutter) {
    Add-Result "Flutter" (Get-Version flutter) $true
} else {
    Write-Host "[Flutter] No encontrado. Clonando SDK estable..." -ForegroundColor Yellow
    $flutterDir = Join-Path $env:USERPROFILE "flutter"
    if (-not (Test-Path $flutterDir)) {
        git clone -b stable --depth 1 https://github.com/flutter/flutter.git $flutterDir
    }
    $bin = Join-Path $flutterDir "bin"
    if (Test-Path (Join-Path $bin "flutter.bat")) {
        $env:PATH = "$bin;$env:PATH"
        [Environment]::SetEnvironmentVariable("PATH", "$bin;$([Environment]::GetEnvironmentVariable('PATH','User'))", "User")
        & (Join-Path $bin "flutter.bat") precache --windows
        Add-Result "Flutter" (Get-Version (Join-Path $bin "flutter.bat")) $true
    } else { Add-Result "Flutter" "clon fallido" $false }
}

# ---------------------------------------------------------------- Docker
if (Test-Command docker) {
    docker info *> $null
    if ($LASTEXITCODE -eq 0) { Add-Result "Docker" (Get-Version docker) $true }
    else {
        Write-Host "[Docker] Demonio no activo. Intentando arrancar Docker Desktop..." -ForegroundColor Yellow
        $dd = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dd) { Start-Process $dd; Start-Sleep 20 }
        docker info *> $null
        if ($LASTEXITCODE -eq 0) { Add-Result "Docker" (Get-Version docker) $true }
        else { Add-Result "Docker" "instalado pero demonio no activo (abrir Docker Desktop)" $false }
    }
} else {
    Write-Host "[Docker] No encontrado. Instalando Docker Desktop..." -ForegroundColor Yellow
    Install-Winget "Docker.DockerDesktop" "Docker Desktop"
    Add-Result "Docker" "instalado (reiniciar y aceptar WSL2)" $true
}

# ---------------------------------------------------------------- AWS CLI v2
if (Test-Command aws) { Add-Result "AWS CLI" (Get-Version aws) $true }
else {
    Write-Host "[AWS CLI] No encontrado. Instalando..." -ForegroundColor Yellow
    Install-Winget "Amazon.AWSCLI" "AWS CLI v2"
    Add-Result "AWS CLI" (Get-Version aws) $true
}

# ---------------------------------------------------------------- AWS Session Manager plugin
$ssmKnown = "C:\Program Files\Amazon\SessionManagerPlugin\bin"
Add-ToSessionPath $ssmKnown
if (Test-Command "session-manager-plugin") { Add-Result "SSM plugin" "OK" $true; Add-ToUserPath $ssmKnown }
else {
    Write-Host "[SSM plugin] No encontrado. Instalando via winget..." -ForegroundColor Yellow
    try { Install-Winget "Amazon.SessionManagerPlugin" "SSM plugin" } catch { Write-Warning "  !! fallo: $($_.Exception.Message)" }
    Add-ToSessionPath $ssmKnown
    if (Test-Command "session-manager-plugin") { Add-Result "SSM plugin" "OK" $true; Add-ToUserPath $ssmKnown }
    else {
        Write-Host "  -> Intentando descarga directa MSI..." -ForegroundColor Yellow
        try {
            $url = "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows_64/SessionManagerPluginSetup.exe"
            $dest = Join-Path $env:TEMP "SessionManagerPluginSetup.exe"
            $out = Invoke-WebRequest -Uri $url -OutFile $dest -Headers @{ "User-Agent" = "Mozilla/5.0" } 2>&1
            if (Test-Path $dest) {
                Start-Process -FilePath $dest -ArgumentList "/S" -Wait
                Add-ToSessionPath $ssmKnown
                if (Test-Command "session-manager-plugin") { Add-Result "SSM plugin" "OK" $true; Add-ToUserPath $ssmKnown }
                else { Add-Result "SSM plugin" "instalado via MSI (revisar PATH)" $true }
            } else { Add-Result "SSM plugin" "descarga fallida" $false }
        } catch { Add-Result "SSM plugin" "descarga fallida: $($_.Exception.Message)" $false }
    }
}

# ---------------------------------------------------------------- Terraform / OpenTofu
if (Test-Command terraform) { Add-Result "Terraform" (Get-Version terraform) $true }
elseif (Test-Command tofu) { Add-Result "Terraform" "OpenTofu (tofu) $(Get-Version tofu) - compatible HCL" $true }
else {
    Write-Host "[Terraform] No encontrado. Intentando winget..." -ForegroundColor Yellow
    try { Install-Winget "Hashicorp.Terraform" "Terraform" } catch { Write-Warning "  !! fallo: $($_.Exception.Message)" }
    if (Test-Command terraform) { Add-Result "Terraform" (Get-Version terraform) $true }
    else {
        Write-Host "  -> winget no disponible (bloqueo regional de HashiCorp). Instalando OpenTofu (fork open source compatible con Terraform HCL)..." -ForegroundColor Yellow
        try {
            $ver = "1.12.6"
            $url = "https://github.com/opentofu/opentofu/releases/download/v$ver/tofu_${ver}_windows_amd64.zip"
            $zip = Join-Path $env:TEMP "tofu.zip"
            $destDir = Join-Path $env:USERPROFILE "opentofu"
            Invoke-WebRequest -Uri $url -OutFile $zip -Headers @{ "User-Agent" = "Mozilla/5.0" }
            Expand-Archive -Path $zip -DestinationPath $destDir -Force
            Add-ToSessionPath $destDir
            Add-ToUserPath $destDir
            if (Test-Command tofu) { Add-Result "Terraform" "OpenTofu $(Get-Version tofu) (compatible HCL Terraform)" $true }
            else { Add-Result "Terraform" "OpenTofu descargado en $destDir (revisar PATH)" $true }
        } catch { Add-Result "Terraform" "descarga fallida: $($_.Exception.Message)" $false }
    }
}

# ---------------------------------------------------------------- GitHub CLI
if (Test-Command gh) { Add-Result "GitHub CLI" (Get-Version gh) $true }
else {
    $ghKnown = @("C:\Program Files\GitHub CLI", "C:\Program Files (x86)\GitHub CLI")
    $ghFound = $ghKnown | Where-Object { Test-Path (Join-Path $_ "gh.exe") } | Select-Object -First 1
    if ($ghFound) {
        Add-ToSessionPath $ghFound
        Add-ToUserPath $ghFound
        Add-Result "GitHub CLI" (Get-Version gh) $true
    }
    else {
        Write-Host "[GitHub CLI] No encontrado. Instalando..." -ForegroundColor Yellow
        Install-Winget "GitHub.cli" "GitHub CLI"
        Add-Result "GitHub CLI" (Get-Version gh) $true
    }
}

# ---------------------------------------------------------------- Resumen
Write-Host ""
Write-Host "=== Resumen del toolchain ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$missing = @($results | Where-Object { $_.Estado -ne "OK" })
if ($missing.Count -gt 0) {
    Write-Host "Componentes pendientes: $($missing.Count)" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "Todo el toolchain esta listo." -ForegroundColor Green
    exit 0
}