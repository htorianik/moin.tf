data "aws_region" "current" {}

data "aws_acm_certificate" "primary" {
  domain = "*.${var.base_domain}"
}

data "aws_route53_zone" "primary" {
  name = var.base_domain
}