output "lambda_submit_arn" {
  description = "ARN of the submit Lambda function"
  value       = aws_lambda_function.submit.invoke_arn
}

output "lambda_submit_name" {
  description = "Name of the submit Lambda function"
  value       = aws_lambda_function.submit.function_name
}

output "lambda_fetch_arn" {
  description = "ARN of the fetch Lambda function"
  value       = aws_lambda_function.fetch.invoke_arn
}

output "lambda_fetch_name" {
  description = "Name of the fetch Lambda function"
  value       = aws_lambda_function.fetch.function_name
}

output "lambda_processor_arn" {
  description = "ARN of the processor Lambda function"
  value       = aws_lambda_function.processor.arn
}
