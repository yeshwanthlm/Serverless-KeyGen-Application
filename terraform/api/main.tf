resource "aws_apigatewayv2_api" "keygen_api" {
  name          = "keygen-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type", "x-api-key"]
    max_age       = 300
  }

  tags = {
    Name = "keygen-api"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.keygen_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# Submit Integration
resource "aws_apigatewayv2_integration" "submit" {
  api_id                 = aws_apigatewayv2_api.keygen_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_submit_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "submit" {
  api_id    = aws_apigatewayv2_api.keygen_api.id
  route_key = "POST /keygen"
  target    = "integrations/${aws_apigatewayv2_integration.submit.id}"
}

resource "aws_lambda_permission" "api_submit" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_submit_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.keygen_api.execution_arn}/*/*"
}

# Fetch Integration
resource "aws_apigatewayv2_integration" "fetch" {
  api_id                 = aws_apigatewayv2_api.keygen_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_fetch_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch" {
  api_id    = aws_apigatewayv2_api.keygen_api.id
  route_key = "GET /result/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.fetch.id}"
}

resource "aws_lambda_permission" "api_fetch" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_fetch_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.keygen_api.execution_arn}/*/*"
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/keygen-api"
  retention_in_days = 7
}
