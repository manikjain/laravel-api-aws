terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region_a
}

provider "aws" {
  alias  = "replica"
  region = var.region_b
}

module "remote_state" {
  source = "nozaq/remote-state-s3-backend/aws"
  enable_replication = false
  dynamodb_deletion_protection_enabled = false
  s3_bucket_force_destroy = true

  providers = {
    aws         = aws
    aws.replica = aws.replica
  }
}

resource "aws_iam_user" "terraform" {
  name = "TerraformUser"
}

resource "aws_iam_user_policy_attachment" "remote_state_access" {
  user       = aws_iam_user.terraform.name
  policy_arn = module.remote_state.terraform_iam_policy.arn
}