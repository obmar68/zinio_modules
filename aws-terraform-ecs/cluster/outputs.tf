output "cluster_id" {
  value = aws_ecs_cluster.ecs.id
}

output "cluster_arn" {
  description = "The ARN of the created ECS cluster."
  value       = aws_ecs_cluster.ecs.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.ecs.name
}

output "instance_role" {
  value = aws_iam_role.instance.name
}