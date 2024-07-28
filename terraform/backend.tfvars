bucket         = "tf-remote-state20240728222549654700000001"
key            = "development/terraform.tfstate"
region         = "eu-central-1"
encrypt        = true
kms_key_id     = "55e35ebb-784f-4b2d-95ea-66c2198cfe50"
dynamodb_table = "tf-remote-state-lock"