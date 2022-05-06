

terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.7.0"
  }
}

locals {
  application_name = element(
    concat(
      aws_codedeploy_app.application.*.name,
      [var.application_name],
    ),
    0,
  )
  default_deployment_group_name = "${var.application_name}-${var.environment}"
  deployment_group_name         = var.deployment_group_name == "" ? local.default_deployment_group_name : var.deployment_group_name

  ec2_tag_filters = {
    key   = var.ec2_tag_key
    type  = "KEY_AND_VALUE"
    value = var.ec2_tag_value

  }

  enable_trafic_control = var.clb_name != "" || var.target_group_name != ""
}

resource "aws_codedeploy_app" "application" {
  count = var.create_application ? 1 : 0

  name = var.application_name
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name_prefix        = "${local.deployment_group_name}-"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "code_deploy_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.role.name
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name               = local.application_name
  autoscaling_groups     = var.autoscaling_groups
  deployment_config_name = var.deployment_config_name
  deployment_group_name  = local.deployment_group_name
  dynamic "ec2_tag_filter" {
    for_each = var.ec2_tag_key != "" && var.ec2_tag_value != "" ? [local.ec2_tag_filters] : []
    content {
      key   = lookup(ec2_tag_filter.value, "key", null)
      type  = lookup(ec2_tag_filter.value, "type", null)
      value = lookup(ec2_tag_filter.value, "value", null)
    }
  }
  service_role_arn = aws_iam_role.role.arn

  deployment_style {
    deployment_option = local.enable_trafic_control ? "WITH_TRAFFIC_CONTROL" : "WITHOUT_TRAFFIC_CONTROL"
    //deployment_type   = "BLUE_GREEN"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  // blue_green_deployment_config {
  //   deployment_ready_option {
  //     action_on_timeout    = "STOP_DEPLOYMENT"
  //     wait_time_in_minutes = 10
  //   }

  //   green_fleet_provisioning_option {
  //     action = "COPY_AUTO_SCALING_GROUP"
  //   }

  //   terminate_blue_instances_on_deployment_success {
  //     action = "TERMINATE"
  //     termination_wait_time_in_minutes = 2
  //   }

  // }

  load_balancer_info {
    dynamic "elb_info" {
      for_each = var.clb_name == "" ? [] : [var.clb_name]
      content {
        name = elb_info.value
      }
    }

    dynamic "target_group_info" {
      for_each = var.target_group_name == "" ? [] : [var.target_group_name]
      content {
        name = target_group_info.value
      }
    }
  }
}
