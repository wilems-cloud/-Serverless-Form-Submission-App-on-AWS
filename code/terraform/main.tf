provider "aws" {
  region = "us-east-1"
}

# S3 bucket for frontend
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "serverless-form-app-bucket"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Project = "ServerlessFormApp"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = "*"
      Action = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.frontend_bucket.arn}/*"
    }]
  })
}

# DynamoDB Table
resource "aws_dynamodb_table" "form_table" {
  name           = "UserFormData"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "name"

  attribute {
    name = "name"
    type = "S"
  }

  tags = {
    Project = "ServerlessFormApp"
  }
}

# SNS Topic
resource "aws_sns_topic" "form_notification" {
  name = "new-form-entry"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy attachment
resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_custom_policy" {
  name = "lambda_dynamodb_sns"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.form_table.arn
      },
      {
        Action   = "sns:Publish",
        Effect   = "Allow",
        Resource = aws_sns_topic.form_notification.arn
      }
    ]
  })
}

# Lambda: POST
resource "aws_lambda_function" "post_lambda" {
  filename         = "lambda_post.zip"
  function_name    = "FormPostHandler"
  handler          = "lambda_post.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = filebase64sha256("lambda_post.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.form_table.name
      SNS_TOPIC  = aws_sns_topic.form_notification.arn
    }
  }
}

# Lambda: GET
resource "aws_lambda_function" "get_lambda" {
  filename         = "lambda_get.zip"
  function_name    = "FormGetHandler"
  handler          = "lambda_get.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = filebase64sha256("lambda_get.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.form_table.name
    }
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "form_api" {
  name        = "FormSubmissionAPI"
  description = "API Gateway for form GET/POST"
}

resource "aws_api_gateway_resource" "form_resource" {
  rest_api_id = aws_api_gateway_rest_api.form_api.id
  parent_id   = aws_api_gateway_rest_api.form_api.root_resource_id
  path_part   = "form"
}

# POST method
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.form_api.id
  resource_id   = aws_api_gateway_resource.form_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.form_api.id
  resource_id             = aws_api_gateway_resource.form_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_lambda.invoke_arn
}

# GET method
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.form_api.id
  resource_id   = aws_api_gateway_resource.form_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.form_api.id
  resource_id             = aws_api_gateway_resource.form_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_lambda.invoke_arn
}

# Permissions to allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway_post" {
  statement_id  = "AllowAPIGatewayInvokePost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.form_api.execution_arn}/*/POST/form"
}

resource "aws_lambda_permission" "api_gateway_get" {
  statement_id  = "AllowAPIGatewayInvokeGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.form_api.execution_arn}/*/GET/form"
}

# Deploy API
resource "aws_api_gateway_deployment" "form_deploy" {
  depends_on = [
    aws_api_gateway_integration.post_integration,
    aws_api_gateway_integration.get_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.form_api.id
  stage_name  = "prod"
}
