data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  ecr_registry          = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  ecr_image             = "${local.ecr_registry}/${aws_ecr_repository.api.name}:${var.api_image_tag}"
  secret_key_param_name = "/${var.project_prefix}/secret_key"
  api_log_group_name    = "/aws/ec2/${var.project_prefix}-api"
}

resource "aws_ecr_repository" "api" {
  name                 = "delivery-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, { Name = "delivery-api" })
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name               = "${var.project_prefix}-${var.environment}-api"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "media" {
  role       = aws_iam_role.api.name
  policy_arn = var.media_policy_arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.api.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.api.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "runtime" {
  statement {
    sid    = "EcrAuthorization"
    effect = "Allow"

    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPullImage"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = [aws_ecr_repository.api.arn]
  }

  statement {
    sid    = "SsmReadParameters"
    effect = "Allow"

    actions = ["ssm:GetParameter", "ssm:GetParameters"]

    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.db_url_param_name}",
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.db_password_param_name}",
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${local.secret_key_param_name}",
    ]
  }

  statement {
    sid    = "SsmDecrypt"
    effect = "Allow"

    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "runtime" {
  name   = "${var.project_prefix}-${var.environment}-api-runtime"
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.runtime.json
}

resource "aws_iam_instance_profile" "api" {
  name = "${var.project_prefix}-${var.environment}-api"
  role = aws_iam_role.api.name

  tags = var.tags
}

resource "random_password" "secret_key" {
  length  = 64
  special = false
}

resource "aws_ssm_parameter" "secret_key" {
  name        = local.secret_key_param_name
  description = "SECRET_KEY de JWT para la API."
  type        = "SecureString"
  value       = random_password.secret_key.result

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_launch_template" "api" {
  name_prefix   = "${var.project_prefix}-${var.environment}-api-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.api.name
  }

  vpc_security_group_ids = [var.sg_api_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    region                      = var.region
    ecr_registry                = local.ecr_registry
    ecr_image                   = local.ecr_image
    db_url_param                = var.db_url_param_name
    db_password_param           = var.db_password_param_name
    secret_key_param            = local.secret_key_param_name
    api_log_group               = local.api_log_group_name
    s3_bucket                   = var.s3_bucket_id
    environment                 = var.environment
    access_token_expire_minutes = var.access_token_expire_minutes
    refresh_token_expire_days   = var.refresh_token_expire_days
    rate_limit_per_minute       = var.rate_limit_per_minute
    cors_origins                = var.cors_origins
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-api" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "api" {
  name               = "${var.project_prefix}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_alb_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-alb" })
}

resource "aws_lb_target_group" "api" {
  name        = "${var.project_prefix}-${var.environment}-api-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_autoscaling_group" "api" {
  name                      = "${var.project_prefix}-${var.environment}-api-asg"
  desired_capacity          = var.asg_desired_capacity
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [aws_lb_target_group.api.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.api.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-api" })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }
}
