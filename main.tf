terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.1.0"
}

# ecr repository for the app
resource "aws_ecr_repository" "app" {
  name = "${local.application}-${var.environment}-app"

  lifecycle {
    prevent_destroy = true
  }
}

# ecr repository for the nginx build
resource "aws_ecr_repository" "nginx" {
  name = "${local.application}-${var.environment}-nginx"

  lifecycle {
    prevent_destroy = true
  }
}

# efs to store instance data of the app
resource "aws_efs_file_system" "moin_instance" {
  creation_token = "${local.application}-${var.environment}-moin-instance-efs"

  lifecycle {
    prevent_destroy = true
  }
}

# mount point for every public subnet
resource "aws_efs_mount_target" "moin_instance" {
  for_each = toset(var.public_subnet_ids)

  file_system_id  = aws_efs_file_system.moin_instance.id
  subnet_id       = each.key
  security_groups = [aws_security_group.efs.id]
}

# route53 record pointing to the load balancer
resource "aws_route53_record" "lb" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "${var.sub_domain}.${var.base_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
}
