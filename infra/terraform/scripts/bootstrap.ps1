$ErrorActionPreference = "Continue"

$Region = "eu-west-1"
$AccountId = (aws sts get-caller-identity --query Account --output text)
$Bucket = "imagine-delivery-tfstate-$AccountId"
$Table = "imagine-delivery-tfstate-lock"

function Invoke-Aws {
    param([string]$Command)
    $output = & cmd /c "aws $Command 2>&1"
    if ($LASTEXITCODE -ne 0) {
        throw "aws $Command fallo: $output"
    }
    return $output
}

$exists = $false
& cmd /c "aws s3api head-bucket --bucket $Bucket 2>&1" | Out-Null
if ($LASTEXITCODE -eq 0) {
    $exists = $true
}

if (-not $exists) {
    if ($Region -eq "us-east-1") {
        Invoke-Aws "s3api create-bucket --bucket $Bucket --region $Region"
    }
    else {
        Invoke-Aws "s3api create-bucket --bucket $Bucket --region $Region --create-bucket-configuration LocationConstraint=$Region"
    }

    Invoke-Aws "s3api put-bucket-versioning --bucket $Bucket --versioning-configuration Status=Enabled"

    $SseFile = Join-Path $env:TEMP "tfstate-sse.json"
    Set-Content -Path $SseFile -Value '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' -NoNewline -Encoding ascii
    Invoke-Aws "s3api put-bucket-encryption --bucket $Bucket --server-side-encryption-configuration file://$SseFile"
    Invoke-Aws "s3api put-public-access-block --bucket $Bucket --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

    Write-Host "Bucket de state creado: s3://$Bucket"
}
else {
    Write-Host "Bucket de state ya existe: s3://$Bucket"
}

& cmd /c "aws dynamodb describe-table --table-name $Table --region $Region 2>&1" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Invoke-Aws "dynamodb create-table --table-name $Table --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region $Region"
    Write-Host "Tabla de lock creada: $Table"
}
else {
    Write-Host "Tabla de lock ya existe: $Table"
}

Write-Host "Backend de OpenTofu listo en $Region."