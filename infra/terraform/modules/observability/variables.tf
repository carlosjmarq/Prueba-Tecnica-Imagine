variable "project_prefix" {
  description = "Prefijo de nombres de los recursos (ej. delivery)."
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix del ALB para dimensiones de CloudWatch."
  type        = string
}

variable "rds_identifier" {
  description = "Identificador de la instancia RDS."
  type        = string
}

variable "allocated_storage_gb" {
  description = "Almacenamiento de RDS en GB (para la alarma de espacio libre)."
  type        = number
  default     = 20
}

variable "sns_email" {
  description = "Email suscrito al topico de alertas."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos."
  type        = map(string)
  default     = {}
}
