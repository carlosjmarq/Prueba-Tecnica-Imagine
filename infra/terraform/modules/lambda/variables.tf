variable "project_prefix" {
  description = "Prefijo de nombres de los recursos (ej. delivery)."
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)."
  type        = string
}

variable "region" {
  description = "Region AWS."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets privadas donde corre la Lambda."
  type        = list(string)
}

variable "sg_lambda_id" {
  description = "Security group de la Lambda."
  type        = string
}

variable "db_url_param_name" {
  description = "Parametro SSM con la URL de conexion a RDS."
  type        = string
}

variable "db_password_param_name" {
  description = "Parametro SSM con el password de RDS."
  type        = string
}

variable "order_timeout_minutes" {
  description = "Minutos antes de cancelar un pedido PENDING."
  type        = number
  default     = 15
}

variable "memory_size" {
  description = "Memoria de la Lambda en MB."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Timeout de la Lambda en segundos."
  type        = number
  default     = 120
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos."
  type        = map(string)
  default     = {}
}
