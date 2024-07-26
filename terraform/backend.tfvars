bucket         = "tf-remote-state20240726174222467900000001"
key            = "development/terraform.tfstate"
region         = "eu-central-1"
encrypt        = true
kms_key_id     = "2729d99f-7e8d-4e06-83fc-d2c48109876c"
dynamodb_table = "tf-remote-state-lock"