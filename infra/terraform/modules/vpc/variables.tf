variable "project_prefix" {
  description = "Prefijo de nombres de los recursos (ej. delivery)."
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR principal de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad donde se crean las subnets."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos."
  type        = map(string)
  default     = {}
}
