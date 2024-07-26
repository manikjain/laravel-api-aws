output "APPRUNNER_ECR_ROLE_ARN" {
  value       = aws_iam_role.apprunnerecr.arn
  description = "ARN of the App Runner ECR role"
}

output "DB_ADDRESS" {
    value = aws_db_instance.laravel.address
}

output "ECR_REGISTRY_URL" {
    value = aws_ecr_repository.laravelapi.repository_url
}