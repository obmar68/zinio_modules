resource "aws_autoscaling_group" "nat_instance" {
  name_prefix        = local.name
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  availability_zones = [local.az]

  launch_template {
    id      = aws_launch_template.nat_instance.id
    version = aws_launch_template.nat_instance.latest_version
  }
  dynamic "tag" {
    for_each = merge(var.tags,local.tags)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
