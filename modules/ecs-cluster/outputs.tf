output "cluster_id" {
  description = "ID del cluster ECS"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN del cluster ECS"
  value       = aws_ecs_cluster.main.arn
}

output "log_group_name" {
  description = "Nombre del log group de CloudWatch"
  value       = aws_cloudwatch_log_group.ecs.name
}
