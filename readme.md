
# Laravel API in AWS

This project demonstrates container image based continuous deployment of a sample laravel api to AWS App Runner via the use of Terraform (deploying AWS resources - ECR, RDS) and Github Actions (building and deploying the container image to App Runner).

Table of Contents
=================
* [Architecture](#architecture)
* [Setup](#setup)
  * [Remote state and TF session management (optional)](#remote-state-and-tf-session-management-optional)

## Architecture

## Prerequisites:
1. Docker desktop
1. Terraform (> `v1.9.3` or higher) must be installed on your machine.
1. aws-cli (> `2.17.17` or higher).
1. AWS security credentials - ACCESS_KEY and SECRET_ACCESS_KEY stored in a file such as `~/.aws/credentials`. Refer the following guide to learn how to store your AWS creds: [https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

## Local setup deployment and testing

1. Clone the repository locally. In the root directory of the project, run `docker compose up --build --force-recreate`.

```
% docker compose up --build --force-recreate
[+] Building 48.6s (14/14) FINISHED                                                                                                                                         ........                                                                                                                                         
 => => exporting layers                                                                                                                                                                                                     1.9s
 => => writing image sha256:2abaf4cbba7096598178915cbedce69f4427e4b5f479fb2617dd0a799a9cc3b7                                                                                                                                0.0s
 => => naming to docker.io/library/laravel-api-aws-api                                                                                                                                                                      0.0s
[+] Running 3/3
 ✔ Network laravel-api-aws_default  Created                                                                                                                                                                                 0.0s
 ✔ Container mysql                  Created                                                                                                                                                                                 0.1s
 ✔ Container laravel-api-aws-api-1  Created                                                                                                                                                                                 0.0s
Attaching to api-1, mysql
mysql  | 2024-07-26 18:28:23+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 9.0.1-1.el9 started.
mysql  | 2024-07-26 18:28:23+00:00 [Note] [Entrypoint]: Switching to dedicated user 'mysql'
.........
mysql  | 2024-07-26T18:28:30.157089Z 0 [System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '9.0.1'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL.
api-1  |
api-1  |    INFO  Preparing database.
api-1  |
api-1  |   Creating migration table .......................................... 7ms DONE
api-1  |
api-1  |    INFO  Running migrations.
api-1  |
api-1  |   2014_10_12_000000_create_users_table ............................. 15ms DONE
api-1  |   2014_10_12_100000_create_password_resets_table ................... 11ms DONE
api-1  |   2016_06_01_000001_create_oauth_auth_codes_table .................. 22ms DONE
api-1  |   2016_06_01_000002_create_oauth_access_tokens_table ............... 65ms DONE
api-1  |   2016_06_01_000003_create_oauth_refresh_tokens_table .............. 30ms DONE
api-1  |   2016_06_01_000004_create_oauth_clients_table ...................... 9ms DONE
api-1  |   2016_06_01_000005_create_oauth_personal_access_clients_table ...... 6ms DONE
api-1  |   2017_02_09_031936_create_permission_tables ...................... 142ms DONE
api-1  |   2017_08_08_193843_create_assets_table ............................ 20ms DONE
api-1  |   2019_08_19_000000_create_failed_jobs_table ........................ 4ms DONE
api-1  |   2021_01_10_023024_create_social_providers_table .................. 28ms DONE
api-1  |
api-1  | Encryption keys generated successfully.
api-1  | Personal access client created successfully.
api-1  | Client ID: 1
api-1  | Client secret: OITXkfngeqEhMDbpWxZYjaUj7HqtK6Mk7WXIvUdi
api-1  | Password grant client created successfully.
api-1  | Client ID: 2
api-1  | Client secret: JxT0h9MG87kAF3cRDjd6xlaURIXWJhV9iHcOovp3
api-1  |
api-1  |    INFO  Seeding database.
api-1  |
api-1  |   Database\Seeders\Users\RoleTableSeeder ............................. RUNNING
api-1  |   Database\Seeders\Users\RoleTableSeeder ....................... 48.82 ms DONE
api-1  |
api-1  |   Database\Seeders\Users\UsersTableSeeder ............................ RUNNING
api-1  |   Database\Seeders\Users\UsersTableSeeder ...................... 23.67 ms DONE
api-1  |
api-1  |
api-1  |    INFO  Server running on [http://0.0.0.0:8000].
api-1  |
api-1  |   Press Ctrl+C to stop the server
api-1  |
api-1  |   2024-07-26 18:30:10 ................................................... ~ 0s

```

2. Test with the following `curl` command:

```
% curl --location 'http://127.0.0.1:8000/api/register' \
--header 'Content-Type: application/json' \
--data-raw '{
    "name": "Manik",
    "email": "manik.jain@live.in",
    "password": "password",
    "password_confirmation": "password"
}'
{"data":{"id":"5093ab4f-1871-4e27-b6b1-8d907dcad788","name":"Manik","email":"manik.jain@live.in","created_at":"2024-07-26T18:30:10+00:00","updated_at":"2024-07-26T18:30:10+00:00","roles":{"data":[{"id":"9b05d8dc-99c0-4919-ac4c-9e5cae9d0194","name":"User","created_at":"2024-07-26T18:28:44+00:00","updated_at":"2024-07-26T18:28:44+00:00","permissions":{"data":[]}}]}}}%
```

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

An ECR repostory.
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
3. Infrastructure should now be setup. You should see the following output. Grab the variable value, and update the remaining github actions secrets as indicated earlier. If some part of the values appear to be masked, initialise terraform locally on your system and run `terraform output`.

```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

APPRUNNER_ECR_ROLE_ARN = "arn:aws:iam::**********:role/AppRunnerECRAccessRoleNew"
DB_ADDRESS = "terraform-20240726182320845700000001.cdqgsg06ue6l.***.rds.amazonaws.com"
ECR_REGISTRY_URL = "************.dkr.ecr.***.amazonaws.com/laravelapi"
```
