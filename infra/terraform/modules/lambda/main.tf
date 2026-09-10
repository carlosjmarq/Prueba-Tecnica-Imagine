data "aws_caller_identity" "current" {}

locals {
  function_name = "${var.project_prefix}-order-timeout-canceller"
  package_dir   = "${path.module}/../../../functions/order_timeout_canceller/package"
  package_zip   = "${path.module}/../../../functions/order_timeout_canceller/_build/lambda.zip"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = local.package_dir
  output_path = local.package_zip
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_prefix}-${var.environment}-order-timeout"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "ssm" {
  statement {
    sid    = "ReadDbParameters"
    effect = "Allow"

    actions = ["ssm:GetParameter", "ssm:GetParameters"]

    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.db_url_param_name}",
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.db_password_param_name}",
    ]
  }

  statement {
    sid    = "DecryptParameters"
    effect = "Allow"

    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ssm" {
  name   = "${var.project_prefix}-${var.environment}-order-timeout-ssm"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.ssm.json
}

resource "aws_lambda_function" "canceller" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.12"
  memory_size   = var.memory_size
  timeout       = var.timeout

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      SSM_DB_URL_PARAM      = var.db_url_param_name
      SSM_DB_PASSWORD_PARAM = var.db_password_param_name
      ORDER_TIMEOUT_MINUTES = tostring(var.order_timeout_minutes)
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_lambda_id]
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.basic,
    aws_iam_role_policy_attachment.vpc,
  ]
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.project_prefix}-order-timeout-schedule"
  description         = "Dispara la cancelacion de pedidos PENDING vencidos cada 5 minutos."
  schedule_expression = "cron(0/5 * * * ? *)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "canceller" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "order-timeout-canceller"
  arn       = aws_lambda_function.canceller.arn
}

resource "aws_lambda_permission" "events" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.canceller.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
