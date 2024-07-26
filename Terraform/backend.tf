terraform {
  backend "s3" {
    bucket         = "tf-remote-state20240726105442353600000001"
    key            = "development/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    kms_key_id     = "1935471b-c13e-4787-8b3e-72442731aa90"
    dynamodb_table = "tf-remote-state-lock"
  }
}