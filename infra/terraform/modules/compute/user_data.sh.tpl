#!/bin/bash
set -euo pipefail

dnf install -y docker
systemctl enable --now docker

aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${ecr_registry}

DB_URL=$(aws ssm get-parameter --name "${db_url_param}" --with-decryption --region ${region} --query Parameter.Value --output text)
DB_PASSWORD=$(aws ssm get-parameter --name "${db_password_param}" --with-decryption --region ${region} --query Parameter.Value --output text)
SECRET_KEY=$(aws ssm get-parameter --name "${secret_key_param}" --with-decryption --region ${region} --query Parameter.Value --output text)

docker rm -f api || true

docker run -d \
  --name api \
  --restart unless-stopped \
  -p 8000:8000 \
  --log-driver awslogs \
  --log-opt awslogs-group=${api_log_group} \
  --log-opt awslogs-region=${region} \
  --log-opt awslogs-stream=$(hostname) \
  -e DATABASE_URL="$DB_URL" \
  -e SECRET_KEY="$SECRET_KEY" \
  -e ACCESS_TOKEN_EXPIRE_MINUTES=${access_token_expire_minutes} \
  -e REFRESH_TOKEN_EXPIRE_DAYS=${refresh_token_expire_days} \
  -e STORAGE_BACKEND=s3 \
  -e S3_BUCKET=${s3_bucket} \
  -e S3_REGION=${region} \
  -e S3_ENDPOINT_URL= \
  -e S3_ACCESS_KEY= \
  -e S3_SECRET_KEY= \
  -e ENVIRONMENT=${environment} \
  -e DEBUG=false \
  -e RATE_LIMIT_PER_MINUTE=${rate_limit_per_minute} \
  -e CORS_ORIGINS='${cors_origins}' \
  ${ecr_image}
