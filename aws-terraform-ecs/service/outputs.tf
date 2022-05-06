output "aws_cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.svc.name
}

output "service_name" {
  value = aws_ecs_service.svc.name
}