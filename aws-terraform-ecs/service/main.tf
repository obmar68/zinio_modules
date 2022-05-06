terraform {
  required_version = ">= 0.11"
}

resource "aws_iam_role" "svc" {
  name = "${var.name}-ecs-role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
	{
	  "Sid": "",
	  "Effect": "Allow",
	  "Principal": {
		"Service": "ecs.amazonaws.com"
	  },
	  "Action": "sts:AssumeRole"
	}
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "svc" {
  role       = aws_iam_role.svc.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_cloudwatch_log_group" "svc" {
  name = var.log_groups
  tags = tomap({ "Name" = format("%s", var.name) })
}

resource "aws_ecs_service" "svc" {
  name            = var.name
  cluster         = var.cluster
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  force_new_deployment = true
  deployment_controller {
    type = var.deployment_controller
  }

  scheduling_strategy = var.scheduling_strategy
  tags                = var.tags


  lifecycle {
    ignore_changes = [
      capacity_provider_strategy,
      propagate_tags,
      health_check_grace_period_seconds
    ]
    // prevent_destroy = var.prevent_destroy
  }
  // lifecycle {
  //   create_before_destroy = true
  // }

  // service_registries {
  //   registry_arn = "${aws_service_discovery_service.svc_discovery.arn}"
  // }

}

// resource "aws_service_discovery_private_dns_namespace" "internal" {
//   name        = "iac.local"
//   description = "internal"
//   vpc         = var.vpc_id
// }

// resource "aws_service_discovery_service" "svc_discovery" {
//   name = "dcvr_${var.name}"

//   dns_config {
//     namespace_id = aws_service_discovery_private_dns_namespace.internal.id

//     dns_records {
//       ttl  = 10
//       type = "A"
//     }

//     routing_policy = "MULTIVALUE"
//   }

//   health_check_custom_config {
//     failure_threshold = 1
//   }
// }
