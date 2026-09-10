variable "environment" {
  description = "Entorno de despliegue."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Region AWS."
  type        = string
  default     = "eu-west-1"
}

variable "project_prefix" {
  description = "Prefijo de nombres de los recursos."
  type        = string
  default     = "delivery"
}

variable "db_password" {
  description = "Password maestra de RDS."
  type        = string
  sensitive   = true
}

variable "sns_email" {
  description = "Email suscrito al topico de alertas."
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR principal de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "instance_type" {
  description = "Tipo de instancia EC2 de la API."
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Tamano minimo del ASG."
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Tamano maximo del ASG."
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Capacidad deseada del ASG."
  type        = number
  default     = 1
}

variable "api_image_tag" {
  description = "Tag de la imagen de la API en ECR."
  type        = string
  default     = "latest"
}

variable "allocated_storage_gb" {
  description = "Almacenamiento de RDS en GB."
  type        = number
  default     = 20
}

variable "order_timeout_minutes" {
  description = "Minutos antes de cancelar un pedido PENDING."
  type        = number
  default     = 15
}

variable "access_token_expire_minutes" {
  description = "Expiracion del access token en minutos."
  type        = number
  default     = 15
}

variable "refresh_token_expire_days" {
  description = "Expiracion del refresh token en dias."
  type        = number
  default     = 7
}

variable "rate_limit_per_minute" {
  description = "Limite de requests por minuto."
  type        = number
  default     = 60
}

variable "cors_origins" {
  description = "Origenes CORS permitidos como JSON."
  type        = string
  default     = "[\"*\"]"
}
