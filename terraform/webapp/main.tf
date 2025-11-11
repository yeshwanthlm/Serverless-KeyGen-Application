resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "webapp" {
  bucket = "keygen-webapp-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "keygen-webapp"
  }
}

resource "aws_s3_bucket_public_access_block" "webapp" {
  bucket = aws_s3_bucket.webapp.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "webapp" {
  bucket = aws_s3_bucket.webapp.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.webapp.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.webapp]
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.webapp.id
  key          = "index.html"
  content      = templatefile("${path.root}/../webapp/index.html", {
    api_endpoint = var.api_endpoint
  })
  content_type = "text/html"

  depends_on = [aws_s3_bucket_policy.webapp]
}

data "aws_region" "current" {}
