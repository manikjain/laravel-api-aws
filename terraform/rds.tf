data "aws_security_group" "default" {
  name = "default"
}

# import {
#   to = aws_default_security_group.default
#   id = data.aws_security_group.default.id
# }

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "laravel" {
  name = "laravel"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "example" {
  security_group_id = aws_security_group.laravel.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 3306
}

resource "aws_db_instance" "laravel" {
  allocated_storage    = 5
  storage_type         = "standard"
  publicly_accessible  = true
  db_name              = var.db_name
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [data.aws_security_group.default.id, aws_security_group.laravel.id]
}