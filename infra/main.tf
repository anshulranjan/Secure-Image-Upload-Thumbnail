variable "aws_region" {
  default = "us-east-1"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "images" {
  bucket        = "anshul-local-cloud-storage"
  force_destroy = true
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Lambda can Put, Get, List objects in our bucket (restrict as needed)
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.images.arn,
          "${aws_s3_bucket.images.arn}/*"
        ]
      },
      # Allow publishing logs to CloudWatch
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda: Upload image (API Gateway event)
resource "aws_lambda_function" "upload" {
  function_name = "api_upload"
  filename      = "${path.module}/../lambda/api_upload.zip"
  handler       = "api_upload.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  memory_size   = 128
  timeout       = 10

  environment {
    variables = {
      BUCKET = aws_s3_bucket.images.bucket
    }
  }
}

# Lambda: Thumbnail generator (S3 ObjectCreated event)
resource "aws_lambda_function" "thumbnail" {
  function_name = "thumbnail"
  filename      = "${path.module}/../lambda/thumbnail.zip"
  handler       = "thumbnail.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  memory_size   = 256
  timeout       = 30

  environment {
    variables = {
      BUCKET = aws_s3_bucket.images.bucket
    }
  }
}

# Lambda: Get signed URL (API Gateway event)
resource "aws_lambda_function" "get_url" {
  function_name = "get_url"
  filename      = "${path.module}/../lambda/get_url.zip"
  handler       = "get_url.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  memory_size   = 128
  timeout       = 10

  environment {
    variables = {
      BUCKET = aws_s3_bucket.images.bucket
    }
  }
}

##################################
# API Gateway - REST API
##################################
resource "aws_api_gateway_rest_api" "image_api" {
  name        = "ImageUploadAPI"
  description = "Cloud native image API"
}

# /upload [POST]
resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.image_api.id
  parent_id   = aws_api_gateway_rest_api.image_api.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_method" "upload_post" {
  rest_api_id   = aws_api_gateway_rest_api.image_api.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "upload_lambda_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.image_api.id
  resource_id             = aws_api_gateway_resource.upload.id
  http_method             = aws_api_gateway_method.upload_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.upload.invoke_arn
}

resource "aws_lambda_permission" "apigateway_upload" {
  statement_id  = "AllowExecutionFromAPIGatewayUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_api.execution_arn}/*/POST/upload"
}

# /get-url [GET]
resource "aws_api_gateway_resource" "get_url" {
  rest_api_id = aws_api_gateway_rest_api.image_api.id
  parent_id   = aws_api_gateway_rest_api.image_api.root_resource_id
  path_part   = "get-url"
}

resource "aws_api_gateway_method" "geturl_get" {
  rest_api_id   = aws_api_gateway_rest_api.image_api.id
  resource_id   = aws_api_gateway_resource.get_url.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "geturl_lambda_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.image_api.id
  resource_id             = aws_api_gateway_resource.get_url.id
  http_method             = aws_api_gateway_method.geturl_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_url.invoke_arn
}

resource "aws_lambda_permission" "apigateway_geturl" {
  statement_id  = "AllowExecutionFromAPIGatewayGetUrl"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_url.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_api.execution_arn}/*/GET/get-url"
}

# Deploy API
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.upload_lambda_proxy,
    aws_api_gateway_integration.geturl_lambda_proxy
  ]
  rest_api_id = aws_api_gateway_rest_api.image_api.id
}

# Stage is now managed separately
resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.image_api.id
  deployment_id = aws_api_gateway_deployment.main.id
}

##################################
# Connect S3 to thumbnail Lambda
##################################
resource "aws_lambda_permission" "s3thumb" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.thumbnail.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.images.arn
}

resource "aws_s3_bucket_notification" "image_notify" {
  bucket = aws_s3_bucket.images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.thumbnail.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }
}

##################################
# Outputs
##################################
output "bucket_name" {
  value = aws_s3_bucket.images.bucket
}

output "upload_api_url" {
  value = "https://${aws_api_gateway_rest_api.image_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/upload"
}

output "get_url_api_url" {
  value = "https://${aws_api_gateway_rest_api.image_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/get-url"
}
