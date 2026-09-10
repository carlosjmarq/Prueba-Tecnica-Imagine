output "bucket_id" {
  description = "Nombre del bucket de media."
  value       = aws_s3_bucket.media.id
}

output "bucket_arn" {
  description = "ARN del bucket de media."
  value       = aws_s3_bucket.media.arn
}

output "bucket_regional_domain_name" {
  description = "Dominio regional del bucket."
  value       = aws_s3_bucket.media.bucket_regional_domain_name
}

output "distribution_id" {
  description = "ID de la distribucion CloudFront."
  value       = aws_cloudfront_distribution.media.id
}

output "distribution_arn" {
  description = "ARN de la distribucion CloudFront."
  value       = aws_cloudfront_distribution.media.arn
}

output "distribution_domain" {
  description = "Dominio de la distribucion CloudFront."
  value       = aws_cloudfront_distribution.media.domain_name
}

output "media_policy_arn" {
  description = "ARN de la policy IAM de lectura/escritura del bucket."
  value       = aws_iam_policy.media_rw.arn
}
