# verify.ps1 - Verifica rapidamente el toolchain (sin instalar nada)
# Uso:  powershell -ExecutionPolicy Bypass -File scripts/verify.ps1

$ErrorActionPreference = "Continue"

$tools = @(
    @{ Name = "Git";         Cmd = "git";          Args = "--version" },
    @{ Name = "Node.js";     Cmd = "node";         Args = "--version" },
    @{ Name = "Python";      Cmd = "python";       Args = "--version" },
    @{ Name = "uv";          Cmd = "uv";           Args = "--version" },
    @{ Name = "Flutter";     Cmd = "flutter";      Args = "--version" },
    @{ Name = "Docker";      Cmd = "docker";       Args = "--version" },
    @{ Name = "AWS CLI";     Cmd = "aws";          Args = "--version" },
    @{ Name = "SSM plugin";  Cmd = "session-manager-plugin"; Args = "--version" },
    @{ Name = "Terraform";   Cmd = "terraform";    Args = "version" },
    @{ Name = "GitHub CLI";  Cmd = "gh";           Args = "--version" }
)

Write-Host "=== Verificacion del toolchain ===" -ForegroundColor Cyan
$rows = @()
foreach ($t in $tools) {
    $cmd = Get-Command $t.Cmd -ErrorAction SilentlyContinue
    if ($cmd) {
        $v = (& $t.Cmd $t.Args 2>&1 | Select-Object -First 1)
        $rows += [PSCustomObject]@{ Tool = $t.Name; Version = "$v"; Estado = "OK" }
    } else {
        $rows += [PSCustomObject]@{ Tool = $t.Name; Version = "-"; Estado = "FALTA" }
    }
}
$rows | Format-Table -AutoSize

$missing = @($rows | Where-Object { $_.Estado -ne "OK" })
if ($missing.Count -gt 0) {
    Write-Host "Faltan $($missing.Count) componente(s). Ejecuta: powershell -ExecutionPolicy Bypass -File scripts/setup.ps1" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "Toolchain completo." -ForegroundColor Green
    exit 0
}