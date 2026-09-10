output "alb_dns_name" {
  description = "DNS publico del ALB."
  value       = aws_lb.api.dns_name
}

output "alb_arn" {
  description = "ARN del ALB."
  value       = aws_lb.api.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix del ALB (dimension de CloudWatch)."
  value       = aws_lb.api.arn_suffix
}

output "target_group_arn" {
  description = "ARN del target group de la API."
  value       = aws_lb_target_group.api.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix del target group."
  value       = aws_lb_target_group.api.arn_suffix
}

output "asg_name" {
  description = "Nombre del Auto Scaling Group."
  value       = aws_autoscaling_group.api.name
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR."
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_repository_arn" {
  description = "ARN del repositorio ECR."
  value       = aws_ecr_repository.api.arn
}

output "secret_key_param_name" {
  description = "Nombre del parametro SSM con la SECRET_KEY."
  value       = aws_ssm_parameter.secret_key.name
}

output "api_log_group_name" {
  description = "Nombre del log group de la API."
  value       = local.api_log_group_name
}
