

terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.7.0"
  }
}

locals {
  # favor name over alarm name if both are set
  alarm_name             = var.name != "" ? var.name : var.alarm_name
  provider_alarm_config = var.support_alarms_enabled && var.support_managed ? "enabled" : "disabled"
  customer_alarm_config  = var.customer_alarms_enabled || false == var.support_managed ? "enabled" : "disabled"
  customer_ok_config     = var.customer_alarms_cleared && var.customer_alarms_enabled || false == var.support_managed ? "enabled" : "disabled"

  provider_alarm_actions = {
    enabled  = [local.provider_sns_topic[var.severity]]
    disabled = []
  }

  customer_alarm_actions = {
    enabled  = compact(var.notification_topic)
    disabled = []
  }

  provider_sns_topic = {
    standard  = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:provider-support-standard"
    urgent    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:provider-support-urgent"
    emergency = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:provider-support-emergency"
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  count = var.alarm_count

  alarm_description   = var.alarm_description
  alarm_name          = var.alarm_count > 1 ? format("%v-%03d", local.alarm_name, count.index + 1) : local.alarm_name
  comparison_operator = var.comparison_operator
  dimensions          = var.dimensions[count.index]
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  unit                = var.unit

  alarm_actions = concat(
    local.provider_alarm_actions[local.provider_alarm_config],
    local.customer_alarm_actions[local.customer_alarm_config],
  )

  ok_actions = concat(
    local.provider_alarm_actions[local.provider_alarm_config],
    local.customer_alarm_actions[local.customer_ok_config],
  )
}
