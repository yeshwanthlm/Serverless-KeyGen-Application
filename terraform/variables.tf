variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "serverless-keygen"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "key_ttl_seconds" {
  description = "Time-to-live for generated keys in seconds"
  type        = number
  default     = 86400  # 24 hours
}
