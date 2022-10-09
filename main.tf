provider "aws" {
  region = "us-east-2"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "educationss"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "educationss" {
  name       = "educationss"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "Education"
  }
}

resource "aws_security_group" "rdsss" {
  name   = "education_rdsss"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["192.80.0.0/16"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "education_rdsss"
  }
}

resource "aws_db_parameter_group" "educationss" {
  name   = "educationss"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

provider "random" {}

resource "random_pet" "random" {
  length = 1
}

resource "aws_db_instance" "educationss" {
  identifier             = "${var.db_name}-${random_pet.random.id}"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.1"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.educationss.name
  vpc_security_group_ids = [aws_security_group.rdsss.id]
  parameter_group_name   = aws_db_parameter_group.educationss.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}
