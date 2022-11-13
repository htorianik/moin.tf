resource "aws_security_group" "efs" {
  name        = "${local.application}-${var.environment}-efs"
  description = "Security group for efs mount targets."
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.application}-${var.environment}-efs"
  }
}

resource "aws_security_group" "lb" {
  name        = "${local.application}-${var.environment}-lb"
  description = "Security group for the load balancer."
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.application}-${var.environment}-lb"
  }
}

resource "aws_security_group" "app" {
  name        = "${local.application}-${var.environment}-app"
  description = "Security group for the application."
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.application}-${var.environment}-app"
  }
}

resource "aws_security_group_rule" "lb_ergess_to_app_http" {
  description              = "allow the lb to send tcp :80 (HTTP) traffic to the app"
  security_group_id        = aws_security_group.lb.id
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_ingress_from_lb_http" {
  description              = "allow the app to recieve tcp :80 (HTTP) traffic from the lb"
  security_group_id        = aws_security_group.app.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "app_ergress_to_efs_ntfs" {
  description              = "allow the app to send tcp :2049 (NTFS) to the efs mount point"
  security_group_id        = aws_security_group.app.id
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.efs.id
}

resource "aws_security_group_rule" "efs_ingress_from_app_ntfs" {
  description              = "allow the efs mount point to receive tcp :2049 (NTFS) to the app"
  security_group_id        = aws_security_group.efs.id
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "lb_ingress_from_internet_http" {
  description       = "allow the lb to receive tcp :80 (HTTP) from the internet"
  security_group_id = aws_security_group.lb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:aws-vpc-no-public-ingress-sgr
}

resource "aws_security_group_rule" "lb_ingress_from_internet_https" {
  description       = "allow the lb to receive tcp :443 (HTTPS) from the internet"
  security_group_id = aws_security_group.lb.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:aws-vpc-no-public-ingress-sgr
}

resource "aws_security_group_rule" "app_egress_to_internet_all" {
  description       = "allow the app to send all traffic to the interned so fargate can retrieve ECR images and secrets."
  security_group_id = aws_security_group.app.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:aws-vpc-no-public-egress-sgr
}