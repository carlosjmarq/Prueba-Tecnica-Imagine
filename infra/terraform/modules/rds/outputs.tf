output "db_endpoint" {
  description = "Endpoint (host) de RDS."
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Puerto de RDS."
  value       = aws_db_instance.main.port
}

output "db_identifier" {
  description = "Identificador de la instancia RDS."
  value       = aws_db_instance.main.identifier
}

output "db_name" {
  description = "Nombre de la base de datos."
  value       = aws_db_instance.main.db_name
}

output "db_url_param_name" {
  description = "Nombre del parametro SSM con la URL de conexion."
  value       = aws_ssm_parameter.db_url.name
}

output "db_password_param_name" {
  description = "Nombre del parametro SSM con el password."
  value       = aws_ssm_parameter.db_password.name
}
