resource "random_pet" "lambda_bucket_name" {
  prefix = "lambda-bucket-source"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

data "archive_file" "lambda_source_code" {
  type = "zip"

  source_dir  = "../dist"
  output_path = "../builds/function-${timestamp()}.zip"
}

resource "aws_s3_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "function-${timestamp()}.zip"
  source = data.archive_file.lambda_source_code.output_path

  etag = filemd5(data.archive_file.lambda_source_code.output_path)
}

resource "aws_lambda_function" "check_cluster_lambda_function" {
  function_name = "CheckClusterLambdaFunction"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_hello_world.key

  runtime     = "nodejs16.x"
  handler     = "index.handler"
  memory_size = 128
  timeout     = 60

  environment {
    variables = {
      WEBHOOK_DISCORD_URL = var.webhook_discord_url
    }
  }

  source_code_hash = data.archive_file.lambda_source_code.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}


resource "aws_cloudwatch_log_group" "log_group_check_cluster_lambda_function" {
  name              = "/aws/lambda/${aws_lambda_function.check_cluster_lambda_function.function_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "example" {
  name = "lambda-eks-describe-policy"
  role = aws_iam_role.lambda_exec.name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_permission" "invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_cluster_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule.arn
}

resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  name                = "cloudwatch_event_rule"
  description         = "Trigger Lambda every minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "cloudwatch_target_rule" {
  rule  = aws_cloudwatch_event_rule.cloudwatch_event_rule.name
  arn   = aws_lambda_function.check_cluster_lambda_function.arn
  input = jsonencode({
    "clusterName" : "tonycava-cluster"
  })
}

// { "clusterName": "tonycava-cluster" }