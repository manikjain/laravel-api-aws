data "aws_iam_policy" "apprunnerecr" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role" "apprunnerecr" {
    name = "AppRunnerECRAccessRoleNew"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service = "build.apprunner.amazonaws.com"
          }
        },
      ]
    })
    managed_policy_arns = [data.aws_iam_policy.apprunnerecr.arn]
}
