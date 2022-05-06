

terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.7.0"
  }
}

data "aws_region" "current_region" {
}

data "aws_caller_identity" "current_account" {
}

locals {
  base_tags = {
    ServiceProvider = "MHOC"
    Environment     = var.environment
  }
}

resource "aws_efs_file_system" "fs" {
  creation_token                  = var.name
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_arn
  performance_mode                = var.performance_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  throughput_mode                 = var.provisioned_throughput_in_mibps == 0 ? "bursting" : "provisioned"

  tags = merge(
    local.base_tags,
    {
      "Name" = var.name
    },
    var.tags,
  )
}

resource "aws_efs_mount_target" "mount" {
  count = var.mount_target_subnets_count

  file_system_id  = aws_efs_file_system.fs.id
  security_groups = var.security_groups
  subnet_id       = element(var.mount_target_subnets, count.index)
}

module "efs_burst_credits" {
  source = "git@github.com:obmar68/zinio_modules.git//aws-terraform-cloudwatch_alarm"

  alarm_description        = "EFS Burst Credits have dropped below ${var.cw_burst_credit_threshold} for ${var.cw_burst_credit_period} periods."
  alarm_name               = "${var.name}-EFSBurstCredits"
  comparison_operator      = "LessThanThreshold"
  evaluation_periods       = var.cw_burst_credit_period
  metric_name              = "BurstCreditBalance"
  namespace                = "AWS/EFS"
  notification_topic       = var.notification_topic
  period                   = "3600"
  support_alarms_enabled   = var.support_alarms_enabled
  support_managed        = var.support_managed
  severity                 = "emergency"
  statistic                = "Minimum"
  threshold                = var.cw_burst_credit_threshold
  unit                     = "Count"

  dimensions = [
    {
      FileSystemId = aws_efs_file_system.fs.id
    },
  ]
}

resource "aws_route53_record" "efs" {
  count = var.create_internal_zone_record ? 1 : 0

  name    = var.internal_record_name != "" ? var.internal_record_name : "${var.environment}-${var.name}-efs"
  records = [aws_efs_file_system.fs.dns_name]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.internal_zone_id
}

resource "aws_ssm_parameter" "efs_filesystem_id" {
  count = var.create_parameter_store_entries ? 1 : 0

  name  = "/${var.environment}/${var.name}/efs/filesystem_id"
  type  = "String"
  value = aws_efs_file_system.fs.id
}

resource "aws_ssm_parameter" "efs_fqdn" {
  count = var.create_parameter_store_entries ? 1 : 0

  name  = "/${var.environment}/${var.name}/efs/fqdn"
  type  = "String"
  value = aws_efs_file_system.fs.dns_name
}
