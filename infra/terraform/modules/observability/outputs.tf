output "sns_topic_arn" {
  description = "ARN del topico de alertas."
  value       = aws_sns_topic.alerts.arn
}

output "api_log_group_name" {
  description = "Log group de la API en EC2."
  value       = aws_cloudwatch_log_group.api.name
}

output "alb_log_group_name" {
  description = "Log group del ALB."
  value       = aws_cloudwatch_log_group.alb.name
}

output "lambda_log_group_name" {
  description = "Log group de la Lambda."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "dashboard_name" {
  description = "Nombre del dashboard de CloudWatch."
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
