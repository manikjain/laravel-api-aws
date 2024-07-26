resource "aws_ecr_repository" "laravelapi" {
  name                 = "laravelapi"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}