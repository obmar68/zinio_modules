

terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.7.0"
  }
}

resource "aws_iam_user" "user" {
  count = length(var.user_names)

  name = element(var.user_names, count.index)
  path = "/"
}

resource "aws_iam_group_membership" "team" {
  count = var.group_name == "" ? 0 : 1

  group = element(concat(aws_iam_group.group.*.name, [""]), 0)
  name  = "${var.group_name}-group-membership"
  users = concat(aws_iam_user.user.*.name, var.existing_user_names)
}

resource "aws_iam_group" "group" {
  count = var.group_name == "" ? 0 : 1

  name = var.group_name
  path = "/"
}

resource "aws_iam_group_policy_attachment" "policy" {
  count = var.group_name == "" ? 0 : var.policy_arns_count

  group      = element(concat(aws_iam_group.group.*.name, [""]), 0)
  policy_arn = element(var.policy_arns, count.index)
}
