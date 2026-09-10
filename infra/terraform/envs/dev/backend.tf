terraform {
  backend "s3" {
    bucket         = "imagine-delivery-tfstate-646364595364"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "imagine-delivery-tfstate-lock"
    encrypt        = true
  }
}
