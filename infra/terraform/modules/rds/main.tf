resource "aws_db_subnet_group" "main" {
  name       = "${var.project_prefix}-${var.environment}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-db-subnets" })
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_prefix}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.sg_rds_id]

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:03:00-sun:04:00"

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_prefix}-${var.environment}-postgres-final"

  auto_minor_version_upgrade = true
  apply_immediately          = false
  copy_tags_to_snapshot      = true

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-postgres" })
}

resource "aws_ssm_parameter" "db_url" {
  name        = "/${var.project_prefix}/db/url"
  description = "URL asyncpg de conexion a RDS para la API."
  type        = "SecureString"
  value       = "postgresql+asyncpg://${var.db_username}:${urlencode(var.db_password)}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"

  tags = var.tags
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_prefix}/db/password"
  description = "Password de RDS para consumidores que no usan la URL (Lambda pg8000)."
  type        = "SecureString"
  value       = var.db_password

  tags = var.tags
}
