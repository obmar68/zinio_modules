output "target_group_arn" {
  value = aws_alb_target_group.tg.arn
}

output "target_group_name" {
  value = aws_alb_target_group.tg.name
}
