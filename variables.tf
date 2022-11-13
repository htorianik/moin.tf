locals {
  application = "moin"
  log_group   = "/ecs/moin-${var.environment}"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "cluster_id" {
  type        = string
  description = "FARGATE cluster to launch the service in"
}

variable "base_domain" {
  type        = string
  description = "Base domain"
}

variable "sub_domain" {
  type        = string
  description = "Sub domain"
}