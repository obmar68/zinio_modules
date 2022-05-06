terraform {
  required_version = ">= 0.12.26"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

locals {
  default_tags = {
    Environment = var.environment
  }
  merged_tags = merge(var.tags, local.default_tags)
}



# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TARGET GROUP
# This will perform health checks on the servers and receive requests from the Listerers that match Listener Rules.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_target_group" "tg" {
  name                          = var.target_group_name
  port                          = var.port
  protocol                      = var.protocol
  vpc_id                        = var.vpc_id
  deregistration_delay          = var.deregistration_delay
  slow_start                    = var.slow_start
  tags                          = var.tags
  target_type                   = var.target_type
  load_balancing_algorithm_type = var.load_balancing_algorithm_type

  health_check {
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    interval            = var.health_check_interval
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.stickiness_cookie_duration
    enabled         = var.enable_stickiness
  }
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE LISTENER RULES
# These rules determine which requests get routed to the Target Group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_listener_rule" "http_path" {
  count = var.num_listener_arns

  listener_arn = element(var.listener_arns, count.index)
  priority     = var.listener_rule_starting_priority + count.index

  action {
    target_group_arn = aws_alb_target_group.tg.arn
    type             = "forward"
  }

  dynamic "condition" {
    for_each = [for condition in var.routing_condition : condition.values if condition.field == "path-pattern"]
    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in var.routing_condition : condition.values if condition.field == "host-header"]
    content {
      host_header {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in var.routing_condition : condition.values if condition.field == "http-request-method"]
    content {
      http_request_method {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in var.routing_condition : condition.values if condition.field == "source-ip"]
    content {
      source_ip {
        values = condition.value
      }
    }
  }
}
