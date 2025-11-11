output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api.api_endpoint
}

output "webapp_url" {
  description = "Static website URL"
  value       = module.webapp.webapp_url
}

output "sqs_queue_url" {
  description = "SQS queue URL for key generation requests"
  value       = module.infrastructure.sqs_queue_url
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for storing results"
  value       = module.infrastructure.dynamodb_table_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for Lambda container images"
  value       = module.infrastructure.ecr_repository_url
}
