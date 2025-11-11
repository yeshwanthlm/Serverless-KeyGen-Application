data "archive_file" "lambda_functions" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda"
  output_path = "${path.module}/lambda_functions.zip"
  excludes    = ["processor"]
}

# Note: Docker image must be built and pushed manually before deploying
# Run: ./scripts/build-and-push.sh

# IAM Role for Submit Lambda
resource "aws_iam_role" "lambda_submit_role" {
  name = "keygen-submit-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_submit_basic" {
  role       = aws_iam_role.lambda_submit_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_submit_sqs" {
  name = "keygen-submit-sqs-policy"
  role = aws_iam_role.lambda_submit_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = var.sqs_queue_arn
    }]
  })
}

# Submit Lambda Function
resource "aws_lambda_function" "submit" {
  function_name    = "keygen-submit"
  role             = aws_iam_role.lambda_submit_role.arn
  runtime          = "python3.11"
  handler          = "submit/handler.lambda_handler"
  filename         = data.archive_file.lambda_functions.output_path
  source_code_hash = data.archive_file.lambda_functions.output_base64sha256
  timeout          = 15
  memory_size      = 256

  environment {
    variables = {
      SQS_QUEUE_URL = var.sqs_queue_url
    }
  }

  tags = {
    Name = "keygen-submit"
  }
}

# IAM Role for Fetch Lambda
resource "aws_iam_role" "lambda_fetch_role" {
  name = "keygen-fetch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_fetch_basic" {
  role       = aws_iam_role.lambda_fetch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_fetch_dynamodb" {
  name = "keygen-fetch-dynamodb-policy"
  role = aws_iam_role.lambda_fetch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:Query"
      ]
      Resource = var.dynamodb_table_arn
    }]
  })
}

# Fetch Lambda Function
resource "aws_lambda_function" "fetch" {
  function_name    = "keygen-fetch"
  role             = aws_iam_role.lambda_fetch_role.arn
  runtime          = "python3.11"
  handler          = "fetch/handler.lambda_handler"
  filename         = data.archive_file.lambda_functions.output_path
  source_code_hash = data.archive_file.lambda_functions.output_base64sha256
  timeout          = 15
  memory_size      = 256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = {
    Name = "keygen-fetch"
  }
}

# IAM Role for Processor Lambda
resource "aws_iam_role" "lambda_processor_role" {
  name = "keygen-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_processor_basic" {
  role       = aws_iam_role.lambda_processor_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_processor_sqs" {
  role       = aws_iam_role.lambda_processor_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy" "lambda_processor_dynamodb" {
  name = "keygen-processor-dynamodb-policy"
  role = aws_iam_role.lambda_processor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ]
      Resource = var.dynamodb_table_arn
    }]
  })
}

# Processor Lambda Function (Container)
resource "aws_lambda_function" "processor" {
  function_name = "keygen-processor"
  role          = aws_iam_role.lambda_processor_role.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:latest"
  timeout       = 120
  memory_size   = 512

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = {
    Name = "keygen-processor"
  }
  
  # Allow creation even if image doesn't exist yet
  lifecycle {
    ignore_changes = [image_uri]
  }
}

# SQS Trigger for Processor Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 10
  enabled          = true
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "submit_logs" {
  name              = "/aws/lambda/${aws_lambda_function.submit.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "fetch_logs" {
  name              = "/aws/lambda/${aws_lambda_function.fetch.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "processor_logs" {
  name              = "/aws/lambda/${aws_lambda_function.processor.function_name}"
  retention_in_days = 7
}
