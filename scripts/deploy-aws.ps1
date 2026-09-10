#!/usr/bin/env pwsh
# deploy-aws.ps1 - CLI de despliegue de la infraestructura AWS de la plataforma de delivery.
#
# Automatiza todo el ciclo de deploy real con las herramientas ya instaladas
# (AWS CLI, OpenTofu, Docker, Python/uv) asumiendo que el usuario tiene su
# cuenta de AWS configurada en el CLI (`aws configure`).
#
# Cross-platform: PowerShell 7 (pwsh) en Windows y Linux. En Windows tambien
# funciona con Windows PowerShell 5.1.
#
# Uso:
#   pwsh -File scripts/deploy-aws.ps1 deploy              # pipeline completo
#   pwsh -File scripts/deploy-aws.ps1 verify              # toolchain + identidad AWS
#   pwsh -File scripts/deploy-aws.ps1 bootstrap           # state bucket S3 + lock DynamoDB
#   pwsh -File scripts/deploy-aws.ps1 lambda              # empaqueta el zip de la Lambda
#   pwsh -File scripts/deploy-aws.ps1 plan                # tofu init + plan
#   pwsh -File scripts/deploy-aws.ps1 apply               # tofu init + plan + apply
#   pwsh -File scripts/deploy-aws.ps1 image               # docker login + build + push ECR
#   pwsh -File scripts/deploy-aws.ps1 refresh             # instance refresh del ASG
#   pwsh -File scripts/deploy-aws.ps1 migrate             # alembic upgrade head via SSM
#   pwsh -File scripts/deploy-aws.ps1 state               # captura baseline del estado esperado
#   pwsh -File scripts/deploy-aws.ps1 check               # compara AWS actual vs baseline
#
# Flags:
#   -Environment dev     # nombre del entorno (default: dev)
#   -AutoApprove         # aplica sin confirmar (tofu apply -auto-approve)
#   -Skip image,migrate  # omite etapas del pipeline
#   -Only refresh        # ejecuta solo una etapa
#   -Baseline path.json  # archivo de baseline alternativo para check/state
#   -TfVars path.tfvars  # archivo tfvars alternativo

[CmdletBinding()]
param(
    [ValidateSet("deploy", "verify", "bootstrap", "lambda", "plan", "apply", "image", "refresh", "migrate", "state", "check")]
    [string]$Command = "deploy",
    [string]$Environment = "dev",
    [switch]$AutoApprove,
    [string[]]$Skip = @(),
    [string]$Only = "",
    [string]$Baseline = "",
    [string]$TfVars = ""
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Configuracion y rutas
# ---------------------------------------------------------------------------

$script:Root = Split-Path -Parent $PSScriptRoot
$script:TfEnv = Join-Path $Root "infra\terraform\envs\$Environment"
$script:DefaultTfVars = Join-Path $TfEnv "terraform.tfvars"
$script:DefaultBaseline = Join-Path $TfEnv "baseline.json"
$script:LambdaDir = Join-Path $Root "infra\functions\order_timeout_canceller"
$script:BackendDir = Join-Path $Root "backend"
$script:Region = "eu-west-1"

# ---------------------------------------------------------------------------
# Helpers de salida
# ---------------------------------------------------------------------------

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "== $Msg ==" -ForegroundColor Cyan
}

function Write-Ok([string]$Msg) {
    Write-Host "  [ok] $Msg" -ForegroundColor Green
}

function Write-WarnMsg([string]$Msg) {
    Write-Host "  [warn] $Msg" -ForegroundColor Yellow
}

function Write-Fail([string]$Msg) {
    Write-Host "  [fail] $Msg" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Helpers de ejecucion
# ---------------------------------------------------------------------------

function Invoke-Cmd {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Args = @(),
        [string]$WorkDir = $Root,
        [bool]$Check = $true,
        [string]$Label = ""
    )

    $label = if ($Label) { $Label } else { "$Exe $($Args -join ' ')" }
    Write-Host "  -> $label" -ForegroundColor DarkGray
    Push-Location $WorkDir
    try {
        & $Exe @Args 2>&1 | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
        if ($LASTEXITCODE -ne 0 -and $Check) {
            throw "Comando fallo con exit code ${LASTEXITCODE}: $Exe $($Args -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
    return $LASTEXITCODE
}

function Get-AwsJson {
    param(
        [Parameter(Mandatory = $true)][string]$Query,
        [string]$Service = "sts",
        [string[]]$AwsArgs = @()
    )
    $out = & aws $Service @AwsArgs --region $Region --query $Query --output json 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return ($out | ConvertFrom-Json)
}

function Test-Tool {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------------------
# Etapa: verify
# ---------------------------------------------------------------------------

function Invoke-Verify {
    Write-Step "verify - toolchain e identidad AWS"

    $required = @("aws", "tofu", "docker", "python", "uv")
    $missing = @()
    foreach ($tool in $required) {
        if (Test-Tool $tool) {
            Write-Ok "$tool disponible"
        }
        else {
            $missing += $tool
            Write-Fail "Falta la herramienta: $tool"
        }
    }
    if ($missing.Count -gt 0) {
        throw "Faltan herramientas: $($missing -join ', ')"
    }

    Write-Host "  -> aws sts get-caller-identity" -ForegroundColor DarkGray
    $account = (& aws sts get-caller-identity --query Account --output text 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $account) {
        throw "No hay credenciales AWS validas. Ejecuta: aws configure"
    }
    Write-Ok "Credenciales AWS validas (account $account)"
}

# ---------------------------------------------------------------------------
# Etapa: bootstrap (state bucket + lock DynamoDB)
# ---------------------------------------------------------------------------

function Invoke-Bootstrap {
    Write-Step "bootstrap - state bucket S3 + tabla de lock"

    $AccountId = (aws sts get-caller-identity --query Account --output text)
    $Bucket = "imagine-delivery-tfstate-$AccountId"
    $Table = "imagine-delivery-tfstate-lock"

    & aws s3api head-bucket --bucket $Bucket --region $Region 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "State bucket ya existe: s3://$Bucket"
    }
    else {
        Write-Host "  -> creando bucket $Bucket" -ForegroundColor DarkGray
        if ($Region -eq "us-east-1") {
            & aws s3api create-bucket --bucket $Bucket --region $Region 2>&1 | Out-Null
        }
        else {
            & aws s3api create-bucket --bucket $Bucket --region $Region --create-bucket-configuration LocationConstraint=$Region 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) { throw "No se pudo crear el state bucket" }
        & aws s3api put-bucket-versioning --bucket $Bucket --versioning-configuration Status=Enabled 2>&1 | Out-Null
        $SseFile = Join-Path $env:TEMP "tfstate-sse.json"
        Set-Content -Path $SseFile -Value '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' -NoNewline -Encoding ascii
        & aws s3api put-bucket-encryption --bucket $Bucket --server-side-encryption-configuration file://$SseFile 2>&1 | Out-Null
        & aws s3api put-public-access-block --bucket $Bucket --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" 2>&1 | Out-Null
        Write-Ok "State bucket creado: s3://$Bucket"
    }

    & aws dynamodb describe-table --table-name $Table --region $Region 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Tabla de lock ya existe: $Table"
    }
    else {
        Write-Host "  -> creando tabla $Table" -ForegroundColor DarkGray
        & aws dynamodb create-table --table-name $Table --attribute-definitions "AttributeName=LockID,AttributeType=S" --key-schema "AttributeName=LockID,KeyType=HASH" --billing-mode PAY_PER_REQUEST --region $Region 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "No se pudo crear la tabla de lock" }
        Write-Ok "Tabla de lock creada: $Table"
    }
}

# ---------------------------------------------------------------------------
# Etapa: lambda (empaquetar zip)
# ---------------------------------------------------------------------------

function Invoke-Lambda {
    Write-Step "lambda - empaquetar order-timeout-canceller"

    if (-not (Test-Path $LambdaDir)) { throw "No existe $LambdaDir" }

    $Package = Join-Path $LambdaDir "package"
    $BuildDir = Join-Path $LambdaDir "_build"
    $ZipPath = Join-Path $BuildDir "lambda.zip"

    if (Test-Path $Package) { Remove-Item -Recurse -Force $Package }
    New-Item -ItemType Directory -Path $Package -Force | Out-Null
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

    Copy-Item (Join-Path $LambdaDir "lambda_function.py") $Package
    Write-Host "  -> pip install -r requirements.txt --target $Package" -ForegroundColor DarkGray
    & python -m pip install --disable-pip-version-check --no-cache-dir -r (Join-Path $LambdaDir "requirements.txt") --target $Package 2>&1 | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
    if ($LASTEXITCODE -ne 0) { throw "pip install de la Lambda fallo" }

    if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
    Compress-Archive -Path (Join-Path $Package "*") -DestinationPath $ZipPath -Force
    Write-Ok "Lambda package listo: $ZipPath"
}

# ---------------------------------------------------------------------------
# Helpers tfvars / secrets
# ---------------------------------------------------------------------------

function Get-TfVarValue {
    param([Parameter(Mandatory = $true)][string]$Key, [string]$File = $TfVars)
    if (-not (Test-Path $File)) { return $null }
    $line = Get-Content $File | Where-Object { $_ -match "^\s*$([regex]::Escape($Key))\s*=" } | Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split "=", 2)[1].Trim().Trim('"')
}

function Ensure-TfVars {
    Write-Step "secrets - verificar terraform.tfvars"

    $tfVars = if ($TfVars) { $TfVars } else { $DefaultTfVars }
    $script:TfVars = $tfVars

    if (-not (Test-Path $tfVars)) {
        Write-Host "  -> creando $tfVars desde terraform.tfvars.example" -ForegroundColor DarkGray
        $example = Join-Path $TfEnv "terraform.tfvars.example"
        if (Test-Path $example) {
            Copy-Item $example $tfVars
        }
        else {
            Set-Content -Path $tfVars -Value "environment    = `"$Environment`"" -NoNewline
        }
    }

    $content = Get-Content $tfVars -Raw

    $dbPassword = Get-TfVarValue "db_password" $tfVars
    if (-not $dbPassword -or $dbPassword -match "change-me|placeholder") {
        if ($env:TF_DB_PASSWORD) {
            $dbPassword = $env:TF_DB_PASSWORD
        }
        else {
            $dbPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
        }
        if ($content -match "db_password\s*=") {
            $content = $content -replace '(?m)^(\s*db_password\s*=\s*).*$', "`${1}`"$dbPassword`""
        }
        else {
            $content += "`ndb_password = `"$dbPassword`""
        }
        Write-Ok "db_password generado/actualizado"
    }

    $snsEmail = Get-TfVarValue "sns_email" $tfVars
    if (-not $snsEmail -or $snsEmail -match "change-me|example.com") {
        if ($env:TF_SNS_EMAIL) {
            $snsEmail = $env:TF_SNS_EMAIL
        }
        else {
            $snsEmail = Read-Host "Email para el topico SNS de alertas"
            if (-not $snsEmail) { throw "Se requiere un email SNS (o la variable de entorno TF_SNS_EMAIL)" }
        }
        if ($content -match "sns_email\s*=") {
            $content = $content -replace '(?m)^(\s*sns_email\s*=\s*).*$', "`${1}`"$snsEmail`""
        }
        else {
            $content += "`nsns_email   = `"$snsEmail`""
        }
        Write-Ok "sns_email configurado"
    }

    Set-Content -Path $tfVars -Value $content -NoNewline
    Write-Ok "terraform.tfvars listo: $tfVars"
}

# ---------------------------------------------------------------------------
# Etapa: plan / apply (OpenTofu)
# ---------------------------------------------------------------------------

function Invoke-TofuPlan {
    Write-Step "plan - tofu init + plan"
    if (-not (Test-Path $TfEnv)) { throw "No existe el entorno Terraform: $TfEnv" }
    Invoke-Cmd "tofu" @("init") $TfEnv
    Invoke-Cmd "tofu" @("plan", "-out=tfplan") $TfEnv
    Write-Ok "Plan generado"
}

function Invoke-TofuApply {
    Write-Step "apply - tofu apply"
    $applyArgs = @("apply")
    if ($AutoApprove) {
        $applyArgs += "-auto-approve"
    }
    elseif (Test-Path (Join-Path $TfEnv "tfplan")) {
        $applyArgs += "tfplan"
    }
    Invoke-Cmd "tofu" $applyArgs $TfEnv
    Write-Ok "Infraestructura aplicada"
}

# ---------------------------------------------------------------------------
# Etapa: image (ECR login + build + push)
# ---------------------------------------------------------------------------

function Get-EcrRepositoryUri {
    $AccountId = (aws sts get-caller-identity --query Account --output text)
    return "$AccountId.dkr.ecr.$Region.amazonaws.com/delivery-api"
}

function Invoke-Image {
    Write-Step "image - ECR login + build + push"

    docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "  Docker no esta corriendo. Esta etapa construye y sube a ECR la imagen de la API" -ForegroundColor Yellow
        Write-Host "  (las instancias EC2 la arrancan con 'docker run'). Opciones:" -ForegroundColor Yellow
        Write-Host "    1. Abre Docker Desktop y reintenta:  deploy-aws.ps1 image" -ForegroundColor Yellow
        Write-Host "    2. Salta esta etapa local y deja que CI lo haga:  deploy-aws.ps1 deploy -Skip image" -ForegroundColor Yellow
        throw "Docker Desktop no esta corriendo (requerido solo por la etapa image)"
    }

    $repo = Get-EcrRepositoryUri
    Write-Host "  -> aws ecr get-login-password | docker login" -ForegroundColor DarkGray
    $pw = aws ecr get-login-password --region $Region
    if ($LASTEXITCODE -ne 0) { throw "Fallo el login ECR" }
    $pw | docker login --username AWS --password-stdin $repo 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "docker login fallo" }

    Invoke-Cmd "docker" @("build", "-t", "$repo`:latest", "-t", "$repo`:$([DateTime]::UtcNow.ToString('yyyyMMddHHmm'))", ".") $BackendDir
    Invoke-Cmd "docker" @("push", "$repo`:latest") $BackendDir
    Write-Ok "Imagen publicada en ECR: $repo`:latest"
}

# ---------------------------------------------------------------------------
# Etapa: refresh (ASG instance refresh)
# ---------------------------------------------------------------------------

function Get-AsgName {
    return "delivery-$Environment-api-asg"
}

function Invoke-Refresh {
    Write-Step "refresh - instance refresh del ASG"

    $asgName = Get-AsgName
    $exists = aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $asgName --region $Region --query "AutoScalingGroups[0].AutoScalingGroupName" --output text 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $exists -or $exists -eq "None") {
        Write-WarnMsg "ASG $asgName no existe; skip refresh"
        return
    }

    $refreshId = aws autoscaling start-instance-refresh --auto-scaling-group-name $asgName --preferences "MinHealthyPercentage=0" --region $Region --query "InstanceRefreshId" --output text
    if ($LASTEXITCODE -ne 0) { throw "No se pudo iniciar el instance refresh" }
    Write-Host "  -> refresh $refreshId iniciado, esperando..." -ForegroundColor DarkGray

    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Seconds 15
        $status = aws autoscaling describe-instance-refreshes --auto-scaling-group-name $asgName --region $Region --query "InstanceRefreshes[0].Status" --output text
        Write-Host "  -> status: $status" -ForegroundColor DarkGray
        if ($status -eq "Successful") { Write-Ok "Instance refresh completado"; return }
        if ($status -eq "Failed" -or $status -eq "Cancelled" -or $status -eq "Rollback") { throw "Instance refresh $status" }
    }
    throw "Instance refresh agotado el timeout"
}

# ---------------------------------------------------------------------------
# Etapa: migrate (Alembic via SSM Run Command)
# ---------------------------------------------------------------------------

function Get-AsgInstanceId {
    $asgName = Get-AsgName
    $instances = aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $asgName --region $Region --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId | [0]" --output text 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $instances -or $instances -eq "None") {
        throw "No hay instancia InService en $asgName"
    }
    return $instances
}

function Invoke-Migrate {
    Write-Step "migrate - alembic upgrade head via SSM"

    $instanceId = Get-AsgInstanceId
    $params = @{ commands = @("docker exec api alembic upgrade head") } | ConvertTo-Json -Compress
    $paramsFile = Join-Path $env:TEMP "ssm-migrate.json"
    Set-Content -Path $paramsFile -Value $params -NoNewline -Encoding ascii

    $cmdId = aws ssm send-command --instance-ids $instanceId --document-name "AWS-RunShellScript" --parameters "file://$paramsFile" --region $Region --query "Command.CommandId" --output text
    if ($LASTEXITCODE -ne 0) { throw "No se pudo lanzar el comando SSM" }
    Write-Host "  -> comando SSM $cmdId lanzado, esperando..." -ForegroundColor DarkGray

    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 10
        $inv = aws ssm get-command-invocation --command-id $cmdId --instance-id $instanceId --region $Region --query "{Status:Status,Out:StandardOutputContent,Err:StandardErrorContent}" --output json 2>$null
        $invObj = $inv | ConvertFrom-Json
        if ($invObj.Status -eq "Success") {
            Write-Host $invObj.Out -ForegroundColor Gray
            Write-Ok "Migraciones aplicadas"
            return
        }
        if ($invObj.Status -eq "Failed" -or $invObj.Status -eq "TimedOut" -or $invObj.Status -eq "Cancelled") {
            Write-Host $invObj.Err -ForegroundColor Red
            throw "Migraciones fallaron: $($invObj.Status)"
        }
        Write-Host "  -> estado: $($invObj.Status)" -ForegroundColor DarkGray
    }
    throw "Migraciones agotaron el timeout"
}

# ---------------------------------------------------------------------------
# Etapa: state / check (baseline)
# ---------------------------------------------------------------------------

function Get-DbTables {
    param([string]$InstanceId)
    if (-not $InstanceId) { return $null }

    $py = @'
import asyncio
import json
import os

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine


async def main():
    e = create_async_engine(os.environ["DATABASE_URL"])
    async with e.connect() as c:
        rs = await c.execute(
            text("SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename")
        )
        tables = [r[0] for r in rs]
        vr = await c.execute(text("SELECT version_num FROM alembic_version"))
        versions = [r[0] for r in vr]
        print(json.dumps({"tables": tables, "alembic_versions": versions}))
    await e.dispose()


asyncio.run(main())
'@
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($py))
    $cmd = "echo $b64 | base64 -d > /tmp/db_check.py && docker cp /tmp/db_check.py api:/tmp/db_check.py && docker exec api python /tmp/db_check.py"
    $params = @{ commands = @($cmd) } | ConvertTo-Json -Compress
    $paramsFile = Join-Path $env:TEMP "ssm-dbcheck.json"
    Set-Content -Path $paramsFile -Value $params -NoNewline -Encoding ascii

    $cmdId = aws ssm send-command --instance-ids $InstanceId --document-name "AWS-RunShellScript" --parameters "file://$paramsFile" --region $Region --query "Command.CommandId" --output text 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }

    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 10
        $inv = aws ssm get-command-invocation --command-id $cmdId --instance-id $InstanceId --region $Region --query "{Status:Status,Out:StandardOutputContent}" --output json 2>$null
        $invObj = $inv | ConvertFrom-Json
        if ($invObj.Status -eq "Success") {
            try { return ($invObj.Out | ConvertFrom-Json) } catch { return $null }
        }
        if ($invObj.Status -eq "Failed") { return $null }
    }
    return $null
}

function Get-LiveState {
    $state = [ordered]@{}

    # Endpoints
    $albDns = aws elbv2 describe-load-balancers --region $Region --names delivery-$Environment-alb --query "LoadBalancers[0].DNSName" --output text 2>$null
    $state.alb_dns = if ($LASTEXITCODE -eq 0 -and $albDns) { $albDns } else { "" }

    $dist = aws cloudfront list-distributions --region $Region --query "DistributionList.Items[?Comment=='delivery-$Environment-media'].[Id,DomainName] | [0]" --output text 2>$null
    $state.cloudfront_domain = if ($LASTEXITCODE -eq 0 -and $dist) { ($dist -split "`t")[1] } else { "" }

    $rdsEndpoint = aws rds describe-db-instances --region $Region --query "DBInstances[?DBInstanceIdentifier=='delivery-$Environment-postgres'].Endpoint.Address | [0]" --output text 2>$null
    $state.rds_endpoint = if ($LASTEXITCODE -eq 0 -and $rdsEndpoint) { $rdsEndpoint } else { "" }

    # RDS config
    $rds = aws rds describe-db-instances --region $Region --query "DBInstances[?DBInstanceIdentifier=='delivery-$Environment-postgres'].[Engine,EngineVersion,DBInstanceClass,MultiAZ,BackupRetentionPeriod,AllocatedStorage,StorageType] | [0]" --output text 2>$null
    if ($LASTEXITCODE -eq 0 -and $rds) {
        $parts = $rds -split "`t"
        $state.rds = [ordered]@{
            engine         = $parts[0]
            engine_version = $parts[1]
            instance_class = $parts[2]
            multi_az       = $parts[3]
            backup_period  = $parts[4]
            storage_gb     = $parts[5]
            storage_type   = $parts[6]
        }
    }
    else {
        $state.rds = [ordered]@{}
    }

    # ASG config
    $asg = aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names delivery-$Environment-api-asg --region $Region --query "AutoScalingGroups[0].[MinSize,MaxSize,DesiredCapacity]" --output text 2>$null
    if ($LASTEXITCODE -eq 0 -and $asg) {
        $parts = $asg -split "`t"
        $state.asg = [ordered]@{ min = $parts[0]; max = $parts[1]; desired = $parts[2] }
    }
    else {
        $state.asg = [ordered]@{}
    }

    # S3
    $s3version = aws s3api get-bucket-versioning --bucket delivery-media-$Environment --region $Region --query "Status" --output text 2>$null
    $state.s3_versioning = if ($LASTEXITCODE -eq 0) { $s3version } else { "" }
    $s3sse = aws s3api get-bucket-encryption --bucket delivery-media-$Environment --region $Region --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm" --output text 2>$null
    $state.s3_sse = if ($LASTEXITCODE -eq 0) { $s3sse } else { "" }

    # SSM params
    $ssm = aws ssm describe-parameters --region $Region --query "Parameters[].Name" --output text 2>$null
    $state.ssm_params = if ($LASTEXITCODE -eq 0 -and $ssm) { ($ssm -split "`t") } else { @() }

    # Log groups
    $logs = aws logs describe-log-groups --region $Region --query "logGroups[?starts_with(logGroupName,'/aws/')].logGroupName" --output text 2>$null
    $state.log_groups = if ($LASTEXITCODE -eq 0 -and $logs) { ($logs -split "`t") | Where-Object { $_ -match "delivery" } } else { @() }

    # SNS
    $sns = aws sns list-topics --region $Region --query "Topics[].TopicArn" --output text 2>$null
    $state.sns_topic = if ($LASTEXITCODE -eq 0 -and $sns) { ($sns -split "`t") | Where-Object { $_ -match "delivery-alerts" } | Select-Object -First 1 } else { "" }

    # Lambda
    $lambda = aws lambda get-function --function-name delivery-order-timeout-canceller --region $Region --query "Configuration.[Runtime,MemorySize,Timeout]" --output text 2>$null
    if ($LASTEXITCODE -eq 0 -and $lambda) {
        $parts = $lambda -split "`t"
        $state.lambda = [ordered]@{ runtime = $parts[0]; memory_mb = $parts[1]; timeout_s = $parts[2] }
    }
    else {
        $state.lambda = [ordered]@{}
    }

    # DB
    $state.db = $null
    try {
        $instanceId = Get-AsgInstanceId
        $state.db = Get-DbTables -InstanceId $instanceId
    }
    catch {
        $state.db = $null
    }

    # Health
    $health = ""
    if ($state.alb_dns) {
        try {
            $resp = Invoke-WebRequest -Uri "http://$($state.alb_dns)/health" -UseBasicParsing -TimeoutSec 20
            $health = "HTTP $($resp.StatusCode)"
        }
        catch {
            $health = "ERROR"
        }
    }
    $state.health = $health

    return $state
}

function Invoke-State {
    Write-Step "state - capturar baseline del estado esperado"

    $baseline = if ($Baseline) { $Baseline } else { $DefaultBaseline }
    $state = Get-LiveState
    $payload = [ordered]@{
        captured_at   = [DateTime]::UtcNow.ToString("o")
        environment   = $Environment
        region        = $Region
        project_prefix = "delivery"
        state         = $state
    }
    $payload | ConvertTo-Json -Depth 6 | Set-Content -Path $baseline -Encoding utf8
    Write-Ok "Baseline guardado: $baseline"
    $payload | ConvertTo-Json -Depth 6
}

function Invoke-Check {
    Write-Step "check - comparar AWS actual vs baseline"

    $baseline = if ($Baseline) { $Baseline } else { $DefaultBaseline }
    if (-not (Test-Path $baseline)) {
        throw "No existe el baseline. Ejecuta primero: deploy-aws.ps1 state"
    }
    $expected = Get-Content $baseline -Raw | ConvertFrom-Json
    $actual = Get-LiveState

    $issues = @()
    $warnings = @()

    # Comparaciones hard
    if ($expected.state.rds -and $actual.rds) {
        foreach ($k in @("engine", "engine_version", "instance_class", "multi_az", "backup_period", "storage_gb", "storage_type")) {
            if ($expected.state.rds.$k -ne $actual.rds.$k) {
                $issues += "rds.${k}: esperado='$($expected.state.rds.$k)' actual='$($actual.rds.$k)'"
            }
        }
    }
    else {
        $warnings += "RDS no disponible para comparar"
    }

    if ($expected.state.asg -and $actual.asg) {
        foreach ($k in @("min", "max", "desired")) {
            if ($expected.state.asg.$k -ne $actual.asg.$k) {
                $issues += "asg.${k}: esperado='$($expected.state.asg.$k)' actual='$($actual.asg.$k)'"
            }
        }
    }

    if ($expected.state.s3_versioning -and $expected.state.s3_versioning -ne $actual.s3_versioning) {
        $issues += "s3_versioning: esperado='$($expected.state.s3_versioning)' actual='$($actual.s3_versioning)'"
    }
    if ($expected.state.s3_sse -and $expected.state.s3_sse -ne $actual.s3_sse) {
        $issues += "s3_sse: esperado='$($expected.state.s3_sse)' actual='$($actual.s3_sse)'"
    }

    $expSsm = @($expected.state.ssm_params) | Sort-Object
    $actSsm = @($actual.ssm_params) | Sort-Object
    $diffSsm = Compare-Object $expSsm $actSsm
    if ($diffSsm) { $issues += "ssm_params difieren: $($diffSsm | Out-String)" }

    $expLogs = @($expected.state.log_groups) | Sort-Object
    $actLogs = @($actual.log_groups) | Sort-Object
    $diffLogs = Compare-Object $expLogs $actLogs
    if ($diffLogs) { $issues += "log_groups difieren: $($diffLogs | Out-String)" }

    if ($expected.state.sns_topic -and $expected.state.sns_topic -ne $actual.sns_topic) {
        $issues += "sns_topic: esperado='$($expected.state.sns_topic)' actual='$($actual.sns_topic)'"
    }

    if ($expected.state.lambda -and $actual.lambda) {
        foreach ($k in @("runtime", "memory_mb", "timeout_s")) {
            if ($expected.state.lambda.$k -ne $actual.lambda.$k) {
                $issues += "lambda.${k}: esperado='$($expected.state.lambda.$k)' actual='$($actual.lambda.$k)'"
            }
        }
    }

    if ($expected.state.db -and $actual.db) {
        $expTables = @($expected.state.db.tables) | Sort-Object
        $actTables = @($actual.db.tables) | Sort-Object
        $diffTables = Compare-Object $expTables $actTables
        if ($diffTables) { $issues += "db.tables difieren: $($diffTables | Out-String)" }
        $expVer = @($expected.state.db.alembic_versions) | Sort-Object
        $actVer = @($actual.db.alembic_versions) | Sort-Object
        $diffVer = Compare-Object $expVer $actVer
        if ($diffVer) { $issues += "db.alembic_versions difieren: $($diffVer | Out-String)" }
    }

    if ($expected.state.health -and $expected.state.health -ne $actual.health) {
        $issues += "health: esperado='$($expected.state.health)' actual='$($actual.health)'"
    }

    # Valores volatiles (info)
    $warnings += "alb_dns actual: $($actual.alb_dns)"
    $warnings += "cloudfront actual: $($actual.cloudfront_domain)"
    $warnings += "rds_endpoint actual: $($actual.rds_endpoint)"

    foreach ($w in $warnings) { Write-WarnMsg $w }

    if ($issues.Count -gt 0) {
        foreach ($i in $issues) { Write-Fail $i }
    }
    else {
        Write-Ok "La infraestructura coincide con el baseline"
    }
}

# ---------------------------------------------------------------------------
# Pipeline deploy
# ---------------------------------------------------------------------------

function Invoke-Deploy {
    $stages = @("verify", "bootstrap", "lambda", "apply", "image", "refresh", "migrate", "check")

    if ($Only) {
        $stages = @($Only)
    }
    else {
        $stages = @($stages | Where-Object { $_ -notin $Skip })
    }

    Write-Host ""
    Write-Host "=== Deploy AWS ($Environment) ===" -ForegroundColor Cyan
    Write-Host "Etapas: $($stages -join ' -> ')" -ForegroundColor DarkGray
    Write-Host ""

    foreach ($stage in $stages) {
        switch ($stage) {
            "verify"    { Invoke-Verify }
            "bootstrap" { Invoke-Bootstrap }
            "lambda"    { Invoke-Lambda }
            "apply"     { Ensure-TfVars; Invoke-TofuPlan; Invoke-TofuApply }
            "image"     { Invoke-Image }
            "refresh"   { Invoke-Refresh }
            "migrate"   { Invoke-Migrate }
            "check"     { Invoke-Check }
        }
    }

    Write-Host ""
    Write-Host "=== Deploy completado ===" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    switch ($Command) {
        "deploy"    { Invoke-Deploy }
        "verify"    { Invoke-Verify }
        "bootstrap" { Invoke-Bootstrap }
        "lambda"    { Invoke-Lambda }
        "plan"      { Ensure-TfVars; Invoke-TofuPlan }
        "apply"     { Ensure-TfVars; Invoke-TofuApply }
        "image"     { Invoke-Image }
        "refresh"   { Invoke-Refresh }
        "migrate"   { Invoke-Migrate }
        "state"     { Invoke-State }
        "check"     { Invoke-Check }
    }
}
catch {
    Write-Fail "ERROR: $($_.Exception.Message)"
}