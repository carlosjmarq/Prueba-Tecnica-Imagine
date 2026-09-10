output "function_name" {
  description = "Nombre de la funcion Lambda."
  value       = aws_lambda_function.canceller.function_name
}

output "function_arn" {
  description = "ARN de la funcion Lambda."
  value       = aws_lambda_function.canceller.arn
}

output "schedule_rule_name" {
  description = "Nombre de la regla de EventBridge."
  value       = aws_cloudwatch_event_rule.schedule.name
}
