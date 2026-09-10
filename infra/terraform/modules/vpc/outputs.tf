output "vpc_id" {
  description = "ID de la VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs de las subnets publicas."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas."
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Zonas de disponibilidad usadas."
  value       = var.availability_zones
}

output "nat_gateway_id" {
  description = "ID del NAT gateway."
  value       = aws_nat_gateway.main.id
}

output "sg_alb_id" {
  description = "Security group del ALB."
  value       = aws_security_group.alb.id
}

output "sg_api_id" {
  description = "Security group de la API."
  value       = aws_security_group.api.id
}

output "sg_rds_id" {
  description = "Security group de RDS."
  value       = aws_security_group.rds.id
}

output "sg_lambda_id" {
  description = "Security group de la Lambda."
  value       = aws_security_group.lambda.id
}
