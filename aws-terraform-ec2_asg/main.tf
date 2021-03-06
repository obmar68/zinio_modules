

terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.1.0"
  }
}

locals {
  ec2_os = lower(var.ec2_os)

  ec2_os_windows_length_test = length(local.ec2_os) >= 7 ? 7 : length(local.ec2_os)
  ec2_os_windows             = substr(local.ec2_os, 0, local.ec2_os_windows_length_test) == "windows" ? true : false

  cw_config_parameter_name = "CWAgent-${var.name}"

  ssm_doc_content = {
    schemaVersion = "2.2"
    description   = "SSM Document for instance configuration."
    parameters    = {}
    mainSteps     = local.ssm_command_list
  }

  ssm_command_list = concat(
    local.default_ssm_cmd_list,
    local.ssm_codedeploy_include[var.install_codedeploy_agent],
    [for s in var.additional_ssm_bootstrap_list : jsondecode(s.ssm_add_step)],
    var.ssm_bootstrap_list,
    local.ssm_update_agent
  )

  # This is a list of ssm main steps
  default_ssm_cmd_list = [
    {
      action = "aws:runDocument",
      inputs = {
        documentPath = "AWS-ConfigureAWSPackage",
        documentParameters = {
          action = "Install",
          name   = "AmazonCloudWatchAgent"
        },
        documentType = "SSMDocument"
      },
      name           = "InstallCWAgent",
      timeoutSeconds = 300
    },
    {
      action = "aws:runDocument",
      inputs = {
        documentPath = "AmazonCloudWatch-ManageAgent",
        documentParameters = {
          action                        = "configure",
          optionalConfigurationSource   = "ssm",
          optionalConfigurationLocation = "${var.provide_custom_cw_agent_config ? var.custom_cw_agent_config_ssm_param : local.cw_config_parameter_name}",
          optionalRestart               = "yes",
          name                          = "AmazonCloudWatchAgent"
        },
        documentType = "SSMDocument"
      },
      name           = "ConfigureCWAgent",
      timeoutSeconds = 300
    },
  ]


//AWSCodeDeployAgent
  ssm_codedeploy_include = {
    true = [
      {
        action = "aws:runDocument",
        inputs = {
          documentPath = "AWS-ConfigureAWSPackage",
          documentParameters = {
            action = "Install",
            name   = "AWSCodeDeployAgent"
          },
          documentType = "SSMDocument"
        },
        name           = "InstallCodeDeployAgent",
        timeoutSeconds = 300
    }
    ]

    false = []
  }


  ssm_update_agent = [
    {
      action = "aws:runDocument",
      inputs = {
        documentPath = "AWS-UpdateSSMAgent",
        documentType = "SSMDocument"
      },
      name           = "UpdateSSMAgent",
      timeoutSeconds = 300
    },
  ]

  ebs_device_map = {
    amazon        = "/dev/sdf"
    amazon2       = "/dev/sdf"
    amazoneks     = "/dev/sdf"
    amazonecs     = "/dev/xvdcz"
    rhel6         = "/dev/sdf"
    rhel7         = "/dev/sdf"
    rhel8         = "/dev/sdf"
    centos6       = "/dev/sdf"
    centos7       = "/dev/sdf"
    centos8       = "/dev/sdf"
    ubuntu14      = "/dev/sdf"
    ubuntu16      = "/dev/sdf"
    ubuntu18      = "/dev/sdf"
    windows2012r2 = "xvdf"
    windows2016   = "xvdf"
    windows2019   = "xvdf"
  }

  cwagent_config = local.ec2_os_windows ? "windows_cw_agent_param.json" : "linux_cw_agent_param.json"

  # local.tags can and should be applied to all taggable resources

  tags = {
    Environment     = var.environment
    ServiceProvider = "MHOC"
  }

  # local.tags_ec2 is applied to the ASG and propagated to all instances

  tags_ec2 = {
    Backup           = var.backup_tag_value
    Name             = var.name
    "Patch Group"    = var.ssm_patching_group
    SSMInventory     = var.perform_ssm_inventory_tag
    "SSM Target Tag" = "Target-${var.name}"
  }

  # local.tags_asg is applied to the ASG but not propagated to the EC2 instances

  tags_asg = {
    InstanceReplacement = var.enable_rolling_updates ? "True" : "False"
  }

  user_data_map = {
    amazon        = "amazon_linux_userdata.sh"
    amazon2       = "amazon_linux_userdata.sh"
    amazonecs     = "amazon_linux_userdata.sh"
    amazoneks     = "amazon_linux_userdata.sh"
    rhel6         = "rhel_centos_6_userdata.sh"
    rhel7         = "rhel_centos_7_userdata.sh"
    rhel8         = "rhel_centos_8_userdata.sh"
    centos6       = "rhel_centos_6_userdata.sh"
    centos7       = "rhel_centos_7_userdata.sh"
    centos8       = "rhel_centos_8_userdata.sh"
    ubuntu14      = "ubuntu_userdata.sh"
    ubuntu16      = "ubuntu_userdata.sh"
    ubuntu18      = "ubuntu_userdata.sh"
    windows2012r2 = "windows_userdata.ps1"
    windows2016   = "windows_userdata.ps1"
    windows2019   = "windows_userdata.ps1"
  }

  ami_owner_mapping = {
    amazon        = "137112412989"
    amazon2       = "137112412989"
    amazonecs     = "591542846629"
    amazoneks     = "602401143452"
    centos6       = "679593333241"
    centos7       = "125523088429"
    centos8       = "125523088429"
    rhel6         = "309956199498"
    rhel7         = "309956199498"
    rhel8         = "309956199498"
    ubuntu14      = "099720109477"
    ubuntu16      = "099720109477"
    ubuntu18      = "099720109477"
    windows2012r2 = "801119661308"
    windows2016   = "801119661308"
    windows2019   = "801119661308"
  }

  ami_name_mapping = {
    amazon        = "amzn-ami-hvm-2018.03.0.*gp2"
    amazon2       = "amzn2-ami-hvm-2.0.*-ebs"
    amazonecs     = "amzn2-ami-ecs-hvm-2*-x86_64-ebs"
    amazoneks     = "amazon-eks-node-*"
    centos6       = "CentOS Linux 6 x86_64 HVM EBS*"
    centos7       = "CentOS 7.* x86_64*"
    centos8       = "CentOS 8.* x86_64*"
    rhel6         = "RHEL-6.*_HVM_GA-*x86_64*"
    rhel7         = "RHEL-7.*_HVM_GA-*x86_64*"
    rhel8         = "RHEL-8.*_HVM-*x86_64*"
    ubuntu14      = "*ubuntu-trusty-14.04-amd64-server*"
    ubuntu16      = "*ubuntu-xenial-16.04-amd64-server*"
    ubuntu18      = "ubuntu/images/hvm-ssd/*ubuntu-bionic-18.04-amd64-server*"
    windows2012r2 = "Windows_Server-2012-R2_RTM-English-64Bit-Base*"
    windows2016   = "Windows_Server-2016-English-Full-Base*"
    windows2019   = "Windows_Server-2019-English-Full-Base*"
  }

  # Any custom AMI filters for a given OS can be added in this mapping
  image_filter = {
    amazon        = []
    amazon2       = []
    amazonecs     = []
    amazoneks     = []
    centos7       = []
    centos8       = []
    rhel6         = []
    rhel7         = []
    rhel8         = []
    ubuntu14      = []
    ubuntu16      = []
    ubuntu18      = []
    windows2012r2 = []
    windows2016   = []
    windows2019   = []
    # Added to ensure only AMIS under the official CentOS 6 product code are retrieved
    centos6 = [
      {
        name   = "product-code"
        values = ["6x5jmcajty9edm3f211pqjfn2"]
      },
    ]
  }

  standard_filters = [
    {
      name   = "virtualization-type"
      values = ["hvm"]
    },
    {
      name   = "root-device-type"
      values = ["ebs"]
    },
    {
      name   = "name"
      values = [local.ami_name_mapping[local.ec2_os]]
    },
  ]
}

# Lookup the correct AMI based on the region specified
data "aws_ami" "asg_ami" {
  most_recent = true
  owners      = [local.ami_owner_mapping[local.ec2_os]]

  dynamic "filter" {
    for_each = concat(local.standard_filters, local.image_filter[local.ec2_os])
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/text/${local.user_data_map[local.ec2_os]}")

  vars = {
    initial_commands = var.initial_userdata_commands
    final_commands   = var.final_userdata_commands
  }
}

data "aws_region" "current_region" {}

data "aws_caller_identity" "current_account" {}

#
# IAM policies
#

data "aws_iam_policy_document" "mod_ec2_assume_role_policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "mod_ec2_instance_role_policies" {

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssm:CreateAssociation",
      "ssm:DescribeInstanceInformation",
      "ssm:GetParameter",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricData",
      "ec2:DescribeTags",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "secretsmanager:GetSecretValue"
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
  }
}

resource "aws_iam_policy" "create_instance_role_policy" {
  count = var.instance_profile_override ? 0 : 1

  description = "provider Instance Role Policies for EC2"
  name        = "InstanceRolePolicy-${var.name}"
  policy      = data.aws_iam_policy_document.mod_ec2_instance_role_policies.json
}

resource "aws_iam_role" "mod_ec2_instance_role" {
  count = var.instance_profile_override ? 0 : 1

  assume_role_policy = data.aws_iam_policy_document.mod_ec2_assume_role_policy_doc.json
  name               = "InstanceRole-${var.name}"
  path               = "/"
}

resource "aws_iam_role_policy_attachment" "attach_core_ssm_policy" {
  count = var.instance_profile_override ? 0 : 1

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.mod_ec2_instance_role[0].name
}

resource "aws_iam_role_policy_attachment" "attach_cw_ssm_policy" {
  count = var.instance_profile_override ? 0 : 1

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.mod_ec2_instance_role[0].name
}

resource "aws_iam_role_policy_attachment" "attach_ad_ssm_policy" {
  count = var.instance_profile_override ? 0 : 1

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
  role       = aws_iam_role.mod_ec2_instance_role[0].name
}

resource "aws_iam_role_policy_attachment" "attach_codedeploy_policy" {
  count = var.install_codedeploy_agent && var.instance_profile_override != true ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
  role       = aws_iam_role.mod_ec2_instance_role[0].name
}

resource "aws_iam_role_policy_attachment" "attach_instance_role_policy" {
  count = var.instance_profile_override ? 0 : 1

  policy_arn = aws_iam_policy.create_instance_role_policy[0].arn
  role       = aws_iam_role.mod_ec2_instance_role[0].name
}

resource "aws_iam_role_policy_attachment" "attach_additonal_policies" {
  count = var.instance_profile_override ? 0 : var.instance_role_managed_policy_arn_count

  policy_arn = element(var.instance_role_managed_policy_arns, count.index)
  role       = aws_iam_role.mod_ec2_instance_role[0].name
}

resource "aws_iam_instance_profile" "instance_role_instance_profile" {
  count = var.instance_profile_override ? 0 : 1

  name = "InstanceRoleInstanceProfile-${var.name}"
  path = "/"
  role = aws_iam_role.mod_ec2_instance_role[0].name
}

#
# Provisioning of ASG related resources
#

resource "aws_launch_configuration" "launch_config_with_secondary_ebs" {
  count = var.secondary_ebs_volume_size != "" ? 1 : 0

  ebs_optimized     = var.enable_ebs_optimization
  enable_monitoring = var.detailed_monitoring
  image_id          = var.image_id != "" ? var.image_id : data.aws_ami.asg_ami.image_id
  instance_type     = var.instance_type
  key_name          = var.key_pair
  name_prefix       = join("-", compact(["LaunchConfigWith2ndEbs", var.name, format("%03d-", count.index + 1)]))
  placement_tenancy = var.tenancy
  security_groups   = var.security_groups
  user_data_base64  = base64encode(data.template_file.user_data.rendered)

  ebs_block_device {
    device_name = local.ebs_device_map[local.ec2_os]
    encrypted   = var.secondary_ebs_volume_existing_id == "" ? var.encrypt_secondary_ebs_volume : false
    iops        = var.secondary_ebs_volume_iops
    snapshot_id = var.secondary_ebs_volume_existing_id
    volume_size = var.secondary_ebs_volume_size
    volume_type = var.secondary_ebs_volume_type
  }

  iam_instance_profile = element(
    coalescelist(
      aws_iam_instance_profile.instance_role_instance_profile.*.name,
      [var.instance_profile_override_name],
    ),
    0,
  )

  root_block_device {
    iops        = var.primary_ebs_volume_type == "io1" ? var.primary_ebs_volume_size : 0
    volume_size = var.primary_ebs_volume_size
    volume_type = var.primary_ebs_volume_type
    encrypted   = var.encrypt_primary_ebs_volume
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "launch_config_no_secondary_ebs" {
  count = var.secondary_ebs_volume_size != "" ? 0 : 1

  ebs_optimized     = var.enable_ebs_optimization
  enable_monitoring = var.detailed_monitoring
  image_id          = var.image_id != "" ? var.image_id : data.aws_ami.asg_ami.image_id
  instance_type     = var.instance_type
  key_name          = var.key_pair
  name_prefix       = join("-", compact(["LaunchConfigNo2ndEbs", var.name, format("%03d-", count.index + 1)]))
  placement_tenancy = var.tenancy
  security_groups   = var.security_groups
  user_data_base64  = base64encode(data.template_file.user_data.rendered)

  iam_instance_profile = element(
    coalescelist(
      aws_iam_instance_profile.instance_role_instance_profile.*.name,
      [var.instance_profile_override_name],
    ),
    0,
  )

  root_block_device {
    volume_type = var.primary_ebs_volume_type
    volume_size = var.primary_ebs_volume_size
    iops        = var.primary_ebs_volume_type == "io1" ? var.primary_ebs_volume_size : 0
    encrypted   = var.encrypt_primary_ebs_volume
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "ec2_scale_up_policy" {
  count = var.enable_scaling_actions ? var.asg_count : 0

  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = element(aws_autoscaling_group.autoscalegrp.*.name, count.index)
  cooldown               = var.ec2_scale_up_cool_down
  name                   = join("-", compact(["ec2_scale_up_policy", var.name, format("%03d", count.index + 1)]))
  scaling_adjustment     = var.ec2_scale_up_adjustment
}

resource "aws_autoscaling_policy" "ec2_scale_down_policy" {
  count = var.enable_scaling_actions ? var.asg_count : 0

  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = element(aws_autoscaling_group.autoscalegrp.*.name, count.index)
  cooldown               = var.ec2_scale_down_cool_down
  name                   = join("-", compact(["ec2_scale_down_policy", var.name, format("%03d", count.index + 1)]))
  scaling_adjustment     = var.ec2_scale_down_adjustment > 0 ? -var.ec2_scale_down_adjustment : var.ec2_scale_down_adjustment
}

resource "aws_autoscaling_group" "autoscalegrp" {
  count = var.asg_count

  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  load_balancers            = var.load_balancer_names
  max_size                  = var.scaling_max
  metrics_granularity       = "1Minute"
  min_size                  = var.scaling_min
  name_prefix               = join("-", compact([var.name,format("%03d-",count.index + 1)]))
  target_group_arns         = var.target_group_arns
  vpc_zone_identifier       = var.subnets
  wait_for_capacity_timeout = var.asg_wait_for_capacity_timeout

  launch_configuration = element(coalescelist(
    aws_launch_configuration.launch_config_with_secondary_ebs.*.name,
    aws_launch_configuration.launch_config_no_secondary_ebs.*.name),
  count.index)

  # This block sets tags provided as objects, allowing the propagate at launch field to be set to False
  dynamic "tag" {
    for_each = var.additional_tags

    content {
      key                 = tag.value.key
      value               = tag.value.value
      propagate_at_launch = lookup(tag.value, "propagate_at_launch", true)
    }
  }

  # This block sets tags provided as a map in the tags variable (propagated to ASG instances).
  dynamic "tag" {
    for_each = merge(var.tags, local.tags_ec2, local.tags)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # This block sets tags provided as a map in the tags_asg variable (not propagated to ASG instances).
  dynamic "tag" {
    for_each = merge(var.tags_asg, local.tags_asg)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  depends_on = [aws_ssm_association.ssm_bootstrap_assoc]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_notification" "scaling_notifications" {
  count = var.enable_scaling_notification ? var.asg_count : 0

  group_names = [element(aws_autoscaling_group.autoscalegrp.*.name, count.index)]
  topic_arn   = var.scaling_notification_topic

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
}

resource "aws_autoscaling_notification" "support_emergency" {
  count = var.provider_managed ? var.asg_count : 0

  group_names = [element(aws_autoscaling_group.autoscalegrp.*.name, count.index)]
  topic_arn   = "arn:aws:sns:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_account.account_id}:support-emergency"
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
}

#
# Provisioning of CloudWatch related resources
#
data "null_data_source" "alarm_dimensions" {
  count = var.asg_count

  inputs = {
    AutoScalingGroupName = element(aws_autoscaling_group.autoscalegrp.*.name, count.index)
  }
}

module "group_terminating_instances" {
  source = "git@github.com:obmar68/zinio_modules.git//aws-terraform-cloudwatch_alarm"

  alarm_count              = var.asg_count
  alarm_description        = "Over ${var.terminated_instances} instances terminated in last 6 hours, generating ticket to investigate."
  alarm_name               = "${var.name}-GroupTerminatingInstances}"
  comparison_operator      = "GreaterThanThreshold"
  dimensions               = data.null_data_source.alarm_dimensions.*.outputs
  evaluation_periods       = 1
  metric_name              = "GroupTerminatingInstances"
  namespace                = "AWS/AutoScaling"
  notification_topic       = var.notification_topic
  period                   = 21600
  support_alarms_enabled = var.provider_alarms_enabled
  support_managed        = var.provider_managed
  severity                 = "emergency"
  statistic                = "Sum"
  threshold                = var.terminated_instances
  unit                     = "Count"
}

resource "aws_cloudwatch_metric_alarm" "scale_alarm_high" {
  count = var.enable_scaling_actions ? var.asg_count : 0

  alarm_actions       = [element(aws_autoscaling_policy.ec2_scale_up_policy.*.arn, count.index)]
  alarm_description   = "Scale-up if ${var.cw_scaling_metric} ${var.cw_high_operator} ${var.cw_high_threshold}% for ${var.cw_high_period} seconds ${var.cw_high_evaluations} times."
  alarm_name          = join("-", compact(["ScaleAlarmHigh", var.name, format("%03d", count.index + 1)]))
  comparison_operator = var.cw_high_operator
  evaluation_periods  = var.cw_high_evaluations
  metric_name         = var.cw_scaling_metric
  namespace           = "AWS/EC2"
  period              = var.cw_high_period
  statistic           = "Average"
  threshold           = var.cw_high_threshold

  dimensions = {
    AutoScalingGroupName = element(aws_autoscaling_group.autoscalegrp.*.name, count.index)
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_alarm_low" {
  count = var.enable_scaling_actions ? var.asg_count : 0

  alarm_actions       = [element(aws_autoscaling_policy.ec2_scale_down_policy.*.arn, count.index)]
  alarm_description   = "Scale-down if ${var.cw_scaling_metric} ${var.cw_low_operator} ${var.cw_low_threshold}% for ${var.cw_low_period} seconds ${var.cw_low_evaluations} times."
  alarm_name          = join("-", compact(["ScaleAlarmLow", var.name, format("%03d", count.index + 1)]))
  comparison_operator = var.cw_low_operator
  evaluation_periods  = var.cw_low_evaluations
  metric_name         = var.cw_scaling_metric
  namespace           = "AWS/EC2"
  period              = var.cw_low_period
  statistic           = "Average"
  threshold           = var.cw_low_threshold

  dimensions = {
    AutoScalingGroupName = element(aws_autoscaling_group.autoscalegrp.*.name, count.index)
  }
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "${var.name}-SystemsLogs"
  retention_in_days = var.cloudwatch_log_retention
}

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "${var.name}-ApplicationLogs"
  retention_in_days = var.cloudwatch_log_retention
}

#
# Provisioning of SSM related resources
#

resource "aws_ssm_document" "ssm_bootstrap_doc" {
  content         = jsonencode(local.ssm_doc_content)
  document_format = "JSON"
  document_type   = "Command"
  name            = "SSMDocument-${var.name}"
}

locals {
  cwagentparam_vars = {
    application_log = aws_cloudwatch_log_group.application_logs.name
    system_log      = aws_cloudwatch_log_group.system_logs.name
  }

  cwagentparam_object = jsondecode(templatefile("${path.module}/text/${local.cwagent_config}", local.cwagentparam_vars))
}

resource "aws_ssm_parameter" "cwagentparam" {
  count = var.provide_custom_cw_agent_config ? 0 : 1

  description = "${var.name} Cloudwatch Agent configuration"
  name        = local.cw_config_parameter_name
  type        = "String"
  value       = jsonencode(local.cwagentparam_object)
}

resource "aws_ssm_association" "ssm_bootstrap_assoc" {
  name                = aws_ssm_document.ssm_bootstrap_doc.name
  schedule_expression = var.ssm_association_refresh_rate

  targets {
    key    = "tag:SSM Target Tag"
    values = ["Target-${var.name}"]
  }

  depends_on = [aws_ssm_document.ssm_bootstrap_doc]
}
