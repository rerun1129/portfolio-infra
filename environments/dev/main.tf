terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "todolist-dev-rerun1129"
    key     = "tfstate/dev/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "portfolio"

    assume_role = {
      role_arn = "arn:aws:iam::740636428516:role/portfolio-terraform-role"
    }
  }
}

locals {
  db_major_version = split(".", var.db_engine_version)[0]
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "${var.project_name}-ec2-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [description] # 기존 import된 SG의 description 보존
  }
}

resource "aws_instance" "main" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name

  vpc_security_group_ids = [aws_security_group.ec2.id]

  credit_specification {
    cpu_credits = "unlimited"
  }

  root_block_device {
    volume_size = 8
    encrypted   = false
  }

  monitoring = false

  tags = {
    Name = "${var.project_name}-server"
  }
}

resource "aws_eip" "main" {
  domain = "vpc"
}

resource "aws_eip_association" "main" {
  instance_id   = aws_instance.main.id
  allocation_id = aws_eip.main.id
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 1000
  storage_type          = "gp2"
  storage_encrypted     = true

  username = "postgres"
  password = var.db_password

  db_name = null

  db_subnet_group_name   = "default-${var.vpc_id}"
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = "default.postgres${local.db_major_version}"
  option_group_name      = "default:postgres-${local.db_major_version}"

  multi_az              = false
  availability_zone     = "${var.aws_region}b"
  publicly_accessible   = true
  copy_tags_to_snapshot = true

  backup_retention_period = 1
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 0

  skip_final_snapshot = true
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_eip.main.public_ip
    origin_id   = "${var.project_name}-ec2-origin"

    custom_origin_config {
      http_port              = var.app_port  # 8080
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name              = "${var.s3_bucket_name}.s3.${var.aws_region}.amazonaws.com"
    origin_id                = "${var.project_name}-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name} EC2 backend"

  ordered_cache_behavior {
    path_pattern             = "todos/*"
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "${var.project_name}-s3-origin"
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
  }

  ordered_cache_behavior {
    path_pattern             = "editor/*"
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "${var.project_name}-s3-origin"
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
  }

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "${var.project_name}-ec2-origin"
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
  }

  price_class = "PriceClass_200" # 한국 포함, PriceClass_All 대비 저렴

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "portfolio"

  assume_role {
    role_arn = var.iam_role_arn
  }

  default_tags {
    tags = {
      Project     = "portfolio"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
