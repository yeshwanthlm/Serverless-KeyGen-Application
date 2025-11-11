output "webapp_url" {
  description = "Static website URL"
  value       = "https://${aws_s3_bucket.webapp.bucket}.s3.${data.aws_region.current.name}.amazonaws.com/index.html"
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.webapp.bucket
}
