# minio-cors.ps1 - Intenta aplicar CORS al bucket de MinIO (dev)
# CORS solo aplica a compilaciones web (navegador). Android/emulador NO lo requiere.
# MinIO (este build) no implementa PutBucketCors: se avisa y se documenta que las
# reglas se aplican en AWS S3 via terraform (ver docs/30 Infraestructura/S3 y CloudFront.md).
# Uso: powershell -ExecutionPolicy Bypass -File scripts/minio-cors.ps1 [-Bucket delivery-media]

param(
    [string]$Bucket = "delivery-media"
)

$corsXml = @'
<?xml version="1.0"?>
<CORSConfiguration>
  <CORSRule>
    <AllowedOrigin>*</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>PUT</AllowedMethod>
    <AllowedMethod>HEAD</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
    <ExposeHeader>ETag</ExposeHeader>
    <MaxAgeSeconds>3000</MaxAgeSeconds>
  </CORSRule>
</CORSConfiguration>
'@

$tmp = Join-Path $env:TEMP "minio-cors.xml"
Set-Content -Path $tmp -Value $corsXml -Encoding Ascii

docker exec -i imagine-delivery-minio mc alias set local http://localhost:9000 minioadmin minioadmin | Out-Null
docker cp $tmp "imagine-delivery-minio:/tmp/minio-cors.xml"
docker exec imagine-delivery-minio mc cors set "local/$Bucket" /tmp/minio-cors.xml
$rc = $LASTEXITCODE
docker exec imagine-delivery-minio rm -f /tmp/minio-cors.xml | Out-Null
Remove-Item $tmp -Force

if ($rc -ne 0) {
    Write-Warning "MinIO (este build) no implementa bucket CORS (NotImplemented). Las reglas CORS deben aplicarse en AWS S3 via terraform. No afecta a Android/emulador."
    exit 0
}
Write-Host "CORS aplicado al bucket '$Bucket' en MinIO."