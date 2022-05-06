
terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.7.0"
  }
}

resource "aws_sns_topic" "topic" {
  name                        = var.name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic
}

resource "aws_sns_topic_subscription" "subscription1" {
  count = var.create_subscription_1 ? 1 : 0

  endpoint               = var.endpoint_1
  endpoint_auto_confirms = var.endpoint_auto_confirms_1
  protocol               = var.protocol_1
  topic_arn              = aws_sns_topic.topic.arn
}

resource "aws_sns_topic_subscription" "subscription2" {
  count = var.create_subscription_2 ? 1 : 0

  endpoint               = var.endpoint_2
  endpoint_auto_confirms = var.endpoint_auto_confirms_2
  protocol               = var.protocol_2
  topic_arn              = aws_sns_topic.topic.arn
}

resource "aws_sns_topic_subscription" "subscription3" {
  count = var.create_subscription_3 ? 1 : 0

  endpoint               = var.endpoint_3
  endpoint_auto_confirms = var.endpoint_auto_confirms_3
  protocol               = var.protocol_3
  topic_arn              = aws_sns_topic.topic.arn
}

resource "aws_sns_topic_subscription" "subscription4" {
  count = var.create_subscription_4 ? 1 : 0

  endpoint               = var.endpoint_4
  endpoint_auto_confirms = var.endpoint_auto_confirms_4
  protocol               = var.protocol_4
  topic_arn              = aws_sns_topic.topic.arn
}

resource "aws_sns_topic_subscription" "subscription5" {
  count = var.create_subscription_5 ? 1 : 0

  endpoint               = var.endpoint_5
  endpoint_auto_confirms = var.endpoint_auto_confirms_5
  protocol               = var.protocol_5
  topic_arn              = aws_sns_topic.topic.arn
}
