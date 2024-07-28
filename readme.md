
# Laravel API in AWS

(Built on top of the sample laravel API code in https://github.com/joselfonseca/laravel-api)

This project demonstrates container image based continuous deployment of a sample laravel api to AWS App Runner via the use of Terraform (deploying AWS resources - ECR, RDS) and Github Actions (building and deploying the container image to App Runner).

Table of Contents
=================
* [Architecture](#architecture)
  * [Corner cuts and scope for improvement](#corner-cuts-and-scope-for-improvement)
* [Folder Structure](#folder-structure)
* [Prerequisites](#prerequisites)
* [Local deployment and testing](#local-deployment-and-testing)
* [Setup](#setup)
  * [Remote state and TF session management](#remote-state-and-tf-session-management)
  * [Action Secrets](#action-secrets)
  * [Deployment](#deployment)
  * [Destroy](#destroy)

## Architecture

For container-based deployments in AWS, while there are more robust and flexible services available like AWS EKS/ECS, for the purposes of this deployment and as the focus is not so much on scalability and redundancy, I chose to use AWS App Runner to run the API with a RDS MySQL instance.

**Continuous Deployment Limitations (due to underlying PHP code)**: The continuous deployment only works fine the first time. All subsequent times, the container run fails as `php artisan migrate` runs again and fails (DB tables and entries already exist), and the PHP code doesn't seem equiped to handle this failure or to skip the migration (as the DB migration has already taken place the first time).

**Scalability**: App Runner by default can scale up to 25 instances of the API with each instance capable of handling 100 requests per second.

As the API grows in terms of the number of microservices, it would make more sense to move to a better container orchestrator platform such as AWS EKS/ECS.

<img width="759" alt="image" src="https://github.com/user-attachments/assets/b9c07fd2-f9f3-46ba-91f7-edd5b581cb10">

### Corner cuts and scope for improvement

For the purposes of this example deployment, the following things could be improved about the whole deployment:

1. **Non-root docker image**: The Docker image runs with a root user. Docker images should be configured with a non-root user for security reasons.
2. **RDS Publicly exposed**: RDS DB is accessible over a public endpoint. This was done to make it easier to connect to the MySQL instance from my local machine. Ideally, the RDS DB exist in a private subnet in a non-default VPC and made accessible via a jumphost in the same VPC. App Runner connects to the RDS DB via public internet. Once RDS is made private in a VPC, App Runner could be configured to privately connect to the RDS instance via VPC connectors.

   **Desirable setup for production:**

   ![image](https://github.com/user-attachments/assets/d6941420-a06a-4972-ba7c-ab0f232e2791)
3. Redis/Memcached were not used (/disabled) with the api to keep the deployment simple.
4. **Redundancy**: The setup doesn't use replication. Replication/Fault tolderance/High availability could be setup for RDS and the API (using another service other than App Runner).

## Folder structure

    .
    ├── .github/workflows (dir)        # Github workflows/actions
    |   ├── build-deploy.yaml          # Action for build and deploy docker image
    |   ├── destroy-infrastructure.yaml# Terraform for destroying infrastructure
    |   └── setup-infrastructure.yaml  # Terraform for setting up infrastructure
    ├── deploy (dir)                   # Deploy configuration for docker image
    |   ├── *.conf, *.ini              # Configuration files
    |   └── run                        # Shell script (docker entrypoint)
    ├── terraform (dir)                # Lambda functions/handlers
    |   ├── remote-state (dir)         # Terraform files for setting up remote state artifacts in S3 and dynamodb
    |   └── *.tf                       # Terraform files for setting up infrastructure
    ├── testdeploy.txt                 # To trigger build and deploy action to AWS ECR and App Runner respectively
    ├── Dockerfile.local               # Dockerfile for local development
    ├── Dockerfile.aws                 # Dockerfile for AWS
    └── README.md

## Prerequisites:
1. Docker desktop
1. Terraform (> `v1.9.3` or higher) must be installed on your machine.
1. aws-cli (> `2.17.17` or higher).
1. AWS security credentials - ACCESS_KEY and SECRET_ACCESS_KEY stored in a file such as `~/.aws/credentials`. Refer the following guide to learn how to store your AWS creds: [https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

## Local deployment and testing

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
    "email": "manik.jain@example.in",
    "password": "password",
    "password_confirmation": "password"
}'
{"data":{"id":"5093ab4f-1871-4e27-b6b1-8d907dcad788","name":"Manik","email":"manik.jain@example.in","created_at":"2024-07-26T18:30:10+00:00","updated_at":"2024-07-26T18:30:10+00:00","roles":{"data":[{"id":"9b05d8dc-99c0-4919-ac4c-9e5cae9d0194","name":"User","created_at":"2024-07-26T18:28:44+00:00","updated_at":"2024-07-26T18:28:44+00:00","permissions":{"data":[]}}]}}}%
```

3. Check the local MySQL DB table for changes:

```
% mysql -h 127.0.0.1 -P 3306 -u root -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 26
Server version: 9.0.1 MySQL Community Server - GPL

Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> use laravel;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> select * from users;
+----+--------------+--------------------------------------+--------------------+---------------------+--------------------------------------------------------------+----------------+---------------------+---------------------+------------+
| id | name         | uuid                                 | email              | email_verified_at   | password                                                     | remember_token | created_at          | updated_at          | deleted_at |
+----+--------------+--------------------------------------+--------------------+---------------------+--------------------------------------------------------------+----------------+---------------------+---------------------+------------+
|  1 | Jose Fonseca | cd687540-fe23-3e5f-8eab-3e8aef2b7757 | jose@example.com   | 2024-07-26 18:28:44 | $2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi | ShybqM0vwc     | 2024-07-26 18:28:44 | 2024-07-26 18:28:44 | NULL       |
|  2 | Manik        | 5093ab4f-1871-4e27-b6b1-8d907dcad788 | manik.jain@example.in | NULL                | $2y$10$bHIWyjB4oaILei6RI4HgwepA/o6gphnYewJjJ3.NHm9MJOrWBrc3m | NULL           | 2024-07-26 18:30:10 | 2024-07-26 18:30:10 | NULL       |
+----+--------------+--------------------------------------+--------------------+---------------------+--------------------------------------------------------------+----------------+---------------------+---------------------+------------+
2 rows in set (0.01 sec)

mysql>
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
6. **Do not remove** the local terraform state file from your system, we will need it later to destroy these resources.

### Action Secrets

Navigate to https://github.com/manikjain/laravel-api-aws/settings/secrets/actions to setup the following secrets. The value of `APPRUNNER_ECR_ROLE_ARN`, `DB_AWS_RDS_HOST`, `ECR_REGISTRY` will be known after the terraform run and can be updated later.

<img width="822" alt="action_secrets" src="https://github.com/user-attachments/assets/f0340587-3836-4953-a46d-e81a31f5c5f8">

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
3. Infrastructure should now be setup. You should see the following output. Grab the variable values, and update the remaining github actions secrets as indicated earlier. If some part of the values appear to be masked, initialise terraform locally on your system and run `terraform output`.

```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

APPRUNNER_ECR_ROLE_ARN = "arn:aws:iam::**********:role/AppRunnerECRAccessRoleNew"
DB_ADDRESS = "terraform-20240726182320845700000001.cdqgsg06ue6l.***.rds.amazonaws.com"
ECR_REGISTRY_URL = "************.dkr.ecr.***.amazonaws.com/laravelapi"
```
4. Update `testdeploy.txt` and commit the changes to trigger apprunner deploy via `Deploy to App Runner - Image based` github action.
5. Grab the App Runner URL from the job log or find it in AWS.
6. Run the following curl command against the URL to test:

```
% curl --location 'https://cgrjijz6rb.eu-central-1.awsapprunner.com/api/register' \
--header 'Content-Type: application/json' \
--data-raw '{
    "name": "Manik",
    "email": "manik.jain@example.in",
    "password": "password",
    "password_confirmation": "password"
}'
{"data":{"id":"ad670d93-da46-4533-a085-2787ee10cad5","name":"Manik","email":"manik.jain@example.in","created_at":"2024-07-26T19:00:07+00:00","updated_at":"2024-07-26T19:00:07+00:00","roles":{"data":[{"id":"b83c9977-e35f-4c4a-973f-0382c0b3cef1","name":"User","created_at":"2024-07-26T18:52:39+00:00","updated_at":"2024-07-26T18:52:39+00:00","permissions":{"data":[]}}]}}}%
```
7. Check the RDS DB table for changes:

```
% mysql -h terraform-20240726182320845700000001.*********.eu-central-1.rds.amazonaws.com -P 3306 -u root -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 37
Server version: 8.0.35 Source distribution

Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> use laravel;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> select * from users;
+----+--------------+--------------------------------------+-----------------------+---------------------+--------------------------------------------------------------+----------------+---------------------+---------------------+------------+
| id | name         | uuid                                 | email                 | email_verified_at   | password                                                     | remember_token | created_at          | updated_at          | deleted_at |
+----+--------------+--------------------------------------+-----------------------+---------------------+--------------------------------------------------------------+----------------+---------------------+---------------------+------------+
|  1 | Jose Fonseca | f0b26021-f8e9-3a43-ab68-67869f161f67 | jose@example.com      | 2024-07-26 18:52:39 | $2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi | 00OGrEDHkQ     | 2024-07-26 18:52:39 | 2024-07-26 18:52:39 | NULL       |
|  2 | Manik        | ad670d93-da46-4533-a085-2787ee10cad5 | manik.jain@example.in | NULL                | $2y$10$iD7wwF/HzarrNFHFfccEiuHX1vuFb0KGxbyamY1.rcI1sviRx5peG | NULL           | 2024-07-26 19:00:07 | 2024-07-26 19:00:07 | NULL       |
+----+--------------+--------------------------------------+-----------------------+---------------------+--------------------------------------------------------------+----------------+---------------------+---------------------+------------+
2 rows in set (0,03 sec)

mysql>
```

### Destroy

1. [Not recommended in production] For ease of destroying the terraform resources, `Destroy Infrastructure in AWS (not recommended in production)` github action was created.
2. Run the github action to destroy all the resources created.
3. Additionally, on your local system run the following to destroy the remote backend.

```
cd terraform/remote-state
terraform destroy
```
