resource "aws_sqs_queue" "keygen_queue" {
  name                       = "keygen-requests"
  visibility_timeout_seconds = 120
  message_retention_seconds  = 86400
  delay_seconds              = 0
  max_message_size           = 262144
  receive_wait_time_seconds  = 10

  tags = {
    Name        = "keygen-requests"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_dynamodb_table" "keygen_results" {
  name         = "keygen-results"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"

  attribute {
    name = "request_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "keygen-results"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_repository" "keygen_processor" {
  name                 = "keygen-processor"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "keygen-processor"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_lifecycle_policy" "keygen_processor_policy" {
  repository = aws_ecr_repository.keygen_processor.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}
