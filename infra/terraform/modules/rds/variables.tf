variable "project_prefix" {
  description = "Prefijo de nombres de los recursos (ej. delivery)."
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets privadas donde vive la instancia."
  type        = list(string)
}

variable "sg_rds_id" {
  description = "Security group de RDS."
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos."
  type        = string
  default     = "imagine_delivery"
}

variable "db_username" {
  description = "Usuario maestro de la base de datos."
  type        = string
  default     = "imagine_delivery"
}

variable "db_password" {
  description = "Password maestra de la base de datos."
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "Version de PostgreSQL."
  type        = string
  default     = "16.13"
}

variable "instance_class" {
  description = "Clase de instancia RDS."
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "Almacenamiento asignado en GB."
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Habilitar alta disponibilidad Multi-AZ."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Dias de retencion de backups automaticos."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos."
  type        = map(string)
  default     = {}
}
