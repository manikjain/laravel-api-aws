
# Laravel API in AWS

This project demonstrates container image based continuous deployment of a sample laravel api to AWS App Runner via the use of Terraform (deploying AWS resources - ECR, RDS) and Github Actions (building and deploying the container image to App Runner).

Table of Contents
=================
* [Architecture](#architecture)
* [Setup](#setup)
  * [Remote state and TF session management (optional)](#remote-state-and-tf-session-management-optional)

## Architecture

## Prerequisites:
1. Terraform (> `v1.9.3` or higher) must be installed on your machine.
1. aws-cli (> `2.17.17` or higher).
1. AWS security credentials - ACCESS_KEY and SECRET_ACCESS_KEY stored in a file such as `~/.aws/credentials`. Refer the following guide to learn how to store your AWS creds: [https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

## Setup

### Remote state and TF session management

The following steps set up an S3 bucket, KMS keys for encrypting state files, dynamoDB table for state locking. You can read more about what we will setup here at this link: https://registry.terraform.io/modules/nozaq/remote-state-s3-backend/aws/latest.

1. Clone the repository locally. `cd terraform/remote-state/`
2. Populate the `terraform.tfvars` file as follows:

```
region_a  =  "eu-central-1" # Choose a region 1
region_b  =  "eu-west-3" # Choose a region 2, note that state replication is disabled, it can be enabled by setting https://github.com/manikjain/laravel-api-aws/blob/develop/Terraform/remote-state/main.tf#L21 to true.
```

3. Setup AWS credentials as per [https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html). Run `terraform init` to initialise.
4. Check with `terraform plan` if everything looks good. Run `terraform apply` to apply the changes. You will receive an output which looks like this:

```
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

kms_key = "xxxxxxx-xxxxxx-xxxx-xxxx"
state_bucket = "tf-remote-state............."
state_dynamo_db = "tf-remote-state-lock"
```

5. Grab the output values from step 4 as per what you received, we will need these to create a remote backend in the deployment steps.

### Action Secrets

Navigate to https://github.com/manikjain/laravel-api-aws/settings/secrets/actions to setup the following secrets. The value of `APPRUNNER_ECR_ROLE_ARN`, `DB_AWS_RDS_HOST`, `ECR_REGISTRY` will be known after the terraform run and can be updated later.

All the required secrets as mentioned here must be in place for the the github actions to work properly.

### Deployment

The following steps mainly set up -

ECR repostory.
RDS MySQL instance (single DB) with a public endpoint and initialised with DB NAME `laravel`.
IAM role for AWS App Runner.

1. Populate the `backend.tfvars` as follows and commit the changes.
```
bucket =  "" # Value as grabbed earlier
key =  "development/terraform.tfstate" # location of state file in S3
region =  "eu-central-1" # region based on region selection earlier
encrypt =  true
kms_key_id =  "xxxxxxx-xxxxxx-xxxx-xxxx" # Key from previous setup
dynamodb_table =  "tf-remote-state-lock"
```
2. Run the github-action `Setup infrastructure in AWS`.
3. Infrastructure should now be setup.