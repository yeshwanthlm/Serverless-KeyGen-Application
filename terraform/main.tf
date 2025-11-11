terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "infrastructure" {
  source = "./infrastructure"
}

module "lambda" {
  source = "./lambda"
  
  sqs_queue_url = module.infrastructure.sqs_queue_url
  sqs_queue_arn = module.infrastructure.sqs_queue_arn
  dynamodb_table_name = module.infrastructure.dynamodb_table_name
  dynamodb_table_arn = module.infrastructure.dynamodb_table_arn
  ecr_repository_url = module.infrastructure.ecr_repository_url
  
  depends_on = [module.infrastructure]
}

module "api" {
  source = "./api"
  
  lambda_submit_arn = module.lambda.lambda_submit_arn
  lambda_submit_name = module.lambda.lambda_submit_name
  lambda_fetch_arn = module.lambda.lambda_fetch_arn
  lambda_fetch_name = module.lambda.lambda_fetch_name
  
  depends_on = [module.lambda]
}

module "webapp" {
  source = "./webapp"
  
  api_endpoint = module.api.api_endpoint
  
  depends_on = [module.api]
}
