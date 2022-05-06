terraform {
  required_version = ">= 0.13"
}

resource "aws_ecs_cluster" "ecs" {
  name = "${var.name}"
  tags = var.tags
}

// resource "aws_ecs_cluster_capacity_providers" "this" {
 
//   cluster_name = aws_ecs_cluster.ecs.name
//   capacity_providers = [aws_ecs_capacity_provider.asg_prov.name]

//   default_capacity_provider_strategy {
//     base              = 1
//     weight            = 100
//     capacity_provider = aws_ecs_capacity_provider.asg_prov.name
//   }
// }

resource "aws_ecs_capacity_provider" "asg_prov" {
  name = "${var.name}_asg_prov"

  auto_scaling_group_provider {
    auto_scaling_group_arn = element(module.ec2_asg.asg_arn_list,0)
    managed_termination_protection = "DISABLED"
    managed_scaling {
      maximum_scaling_step_size = var.asg_max_size
      minimum_scaling_step_size = var.asg_min_size
      status                    = "ENABLED"
      target_capacity           = var.asg_min_size
    }
  }

}

resource "aws_cloudwatch_log_group" "instance" {
  name = "${var.instance_log_group}"
  #tags = "${merge(var.tags, map("Name", format("%s", var.name)))}"
}


#-----------------
# userdata 
#-----------------

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.sh")}"

  vars = {
    additional_user_data_script = "${var.additional_user_data_script}"
    ecs_cluster                 = "${aws_ecs_cluster.ecs.name}"
    log_group                   = "${aws_cloudwatch_log_group.instance.name}"
  }
}



#-----------------
# ASG 
#-----------------

module "ec2_asg" {
  source = "git@github.com:obmar68/zinio_modules.git//aws-terraform-ec2_asg"
  asg_count                              = "1"
  asg_wait_for_capacity_timeout          = "10m"
  backup_tag_value                       = "False"
  cloudwatch_log_retention               = "30"
  cw_high_evaluations                    = "3"
  cw_high_operator                       = "GreaterThanThreshold"
  cw_high_period                         = "60"
  cw_high_threshold                      = "60"
  cw_low_evaluations                     = "3"
  cw_low_operator                        = "LessThanThreshold"
  cw_low_period                          = "300"
  cw_low_threshold                       = "30"
  cw_scaling_metric                      = "CPUUtilization"
  detailed_monitoring                    = false
  ec2_os                                 = "amazonecs"
  ec2_scale_down_adjustment              = "1"
  ec2_scale_down_cool_down               = "60"
  ec2_scale_up_adjustment                = "1"
  ec2_scale_up_cool_down                 = "60"
  enable_ebs_optimization                = false
  enable_scaling_notification            = false
  encrypt_secondary_ebs_volume           = false
  environment                            = var.environment
  health_check_grace_period              = "300"
  health_check_type                      = "EC2"
  install_codedeploy_agent               = false
  instance_profile_override              = true
  instance_profile_override_name         = "${aws_iam_instance_profile.instance.name}"
  // instance_role_managed_policy_arn_count = "0"
  // instance_role_managed_policy_arns      = [aws_iam_policy.test_policy_1.arn, aws_iam_policy.test_policy_2.arn]
  instance_type                          = "${var.instance_type}"
  key_pair                               = "${var.instance_keypair}"
  name                                   = "${var.name}-asg"
  perform_ssm_inventory_tag              = "True"
  primary_ebs_volume_iops                = "0"
  primary_ebs_volume_size                = var.instance_root_volume_size
  primary_ebs_volume_type                = "gp2"
  scaling_max                            = var.asg_max_size
  scaling_min                            = var.asg_min_size
  // scaling_notification_topic          = aws_sns_topic.my_test_sns.arn
  security_groups                        = var.security_groups
  ssm_association_refresh_rate           = "rate(1 day)"
  subnets                                = var.vpc_subnets
  tenancy                                = "default"
  terminated_instances                   = "30"
  target_group_arns                      = [var.alb_target_group_arn]
  final_userdata_commands                = "${data.template_file.user_data.rendered}"
  tags = var.tags
}


#-----------------------
# IAM
#-----------------------

data "aws_iam_policy_document" "instance_policy" {
  statement {
    sid = "CloudwatchPutMetricData"

    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "InstanceLogging"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "${aws_cloudwatch_log_group.instance.arn}",
    ]
  }
}

resource "aws_iam_policy" "instance_policy" {
  name   = "${var.name}-ecs-instance"
  path   = "/"
  policy = "${data.aws_iam_policy_document.instance_policy.json}"
}

resource "aws_iam_role" "instance" {
  name = "${var.name}-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


resource "aws_iam_role_policy_attachment" "instance_policy" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "${aws_iam_policy.instance_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "instance_policy_ssm" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name}-instance-profile"
  role = "${aws_iam_role.instance.name}"
}