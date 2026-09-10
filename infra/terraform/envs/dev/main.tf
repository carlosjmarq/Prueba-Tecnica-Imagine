terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "opentofu"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project_prefix     = var.project_prefix
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  tags               = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  project_prefix     = var.project_prefix
  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  sg_rds_id          = module.vpc.sg_rds_id
  db_password        = var.db_password
  allocated_storage  = var.allocated_storage_gb
  tags               = local.common_tags
}

module "s3_cloudfront" {
  source = "../../modules/s3_cloudfront"

  project_prefix = var.project_prefix
  environment    = var.environment
  tags           = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  project_prefix         = var.project_prefix
  environment            = var.environment
  region                 = var.region
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_subnet_ids     = module.vpc.private_subnet_ids
  sg_alb_id              = module.vpc.sg_alb_id
  sg_api_id              = module.vpc.sg_api_id
  s3_bucket_id           = module.s3_cloudfront.bucket_id
  media_policy_arn       = module.s3_cloudfront.media_policy_arn
  db_url_param_name      = module.rds.db_url_param_name
  db_password_param_name = module.rds.db_password_param_name
  instance_type          = var.instance_type
  asg_min_size           = var.asg_min_size
  asg_max_size           = var.asg_max_size
  asg_desired_capacity   = var.asg_desired_capacity
  api_image_tag          = var.api_image_tag

  access_token_expire_minutes = var.access_token_expire_minutes
  refresh_token_expire_days   = var.refresh_token_expire_days
  rate_limit_per_minute       = var.rate_limit_per_minute
  cors_origins                = var.cors_origins

  tags = local.common_tags
}

module "observability" {
  source = "../../modules/observability"

  project_prefix       = var.project_prefix
  environment          = var.environment
  alb_arn_suffix       = module.compute.alb_arn_suffix
  rds_identifier       = module.rds.db_identifier
  allocated_storage_gb = var.allocated_storage_gb
  sns_email            = var.sns_email
  tags                 = local.common_tags
}

module "lambda" {
  source = "../../modules/lambda"

  project_prefix         = var.project_prefix
  environment            = var.environment
  region                 = var.region
  private_subnet_ids     = module.vpc.private_subnet_ids
  sg_lambda_id           = module.vpc.sg_lambda_id
  db_url_param_name      = module.rds.db_url_param_name
  db_password_param_name = module.rds.db_password_param_name
  order_timeout_minutes  = var.order_timeout_minutes
  tags                   = local.common_tags
}
