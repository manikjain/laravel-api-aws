terraform {
  backend "s3" {
    bucket         = "tf-remote-state20240726140424178200000001"
    key            = "development/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    kms_key_id     = "422ae280-c195-4c4e-9cfb-7e4ce2f63a3d"
    dynamodb_table = "tf-remote-state-lock"
  }
}