

terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.7.0"
  }
}

locals {
  module_tags = {
    Environment     = var.environment
    ServiceProvider = "zinio Inc."
  }
}

resource "aws_route53_zone" "internal_zone" {
  comment = "Hosted zone for ${var.environment}"
  name    = var.name
  tags    = merge(var.tags, local.module_tags)

  vpc {
    vpc_id = var.vpc_id
  }
}
