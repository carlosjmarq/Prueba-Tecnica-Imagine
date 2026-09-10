output "alb_dns" {
  description = "DNS publico del ALB."
  value       = module.compute.alb_dns_name
}

output "bucket" {
  description = "Nombre del bucket de media."
  value       = module.s3_cloudfront.bucket_id
}

output "distribution_domain" {
  description = "Dominio de CloudFront."
  value       = module.s3_cloudfront.distribution_domain
}

output "rds_endpoint" {
  description = "Endpoint de RDS."
  value       = module.rds.db_endpoint
}

output "ecr_repo" {
  description = "URL del repositorio ECR de la API."
  value       = module.compute.ecr_repository_url
}

output "sns_topic_arn" {
  description = "ARN del topico de alertas."
  value       = module.observability.sns_topic_arn
}

output "lambda_function_name" {
  description = "Nombre de la Lambda de cancelacion."
  value       = module.lambda.function_name
}
