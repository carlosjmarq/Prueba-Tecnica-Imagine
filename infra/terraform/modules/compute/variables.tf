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

variable "vpc_id" {
  description = "VPC donde se despliega el compute."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets publicas para el ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subnets privadas para el ASG."
  type        = list(string)
}

variable "sg_alb_id" {
  description = "Security group del ALB."
  type        = string
}

variable "sg_api_id" {
  description = "Security group de las instancias de la API."
  type        = string
}

variable "s3_bucket_id" {
  description = "Nombre del bucket de media."
  type        = string
}

variable "media_policy_arn" {
  description = "ARN de la policy IAM de media a adjuntar al role de EC2."
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

variable "instance_type" {
  description = "Tipo de instancia EC2."
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

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos."
  type        = map(string)
  default     = {}
}
