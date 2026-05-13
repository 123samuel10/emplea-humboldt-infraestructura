output "service_id" {
  description = "ID del servicio ECS"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "ARN de la task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "task_execution_role_arn" {
  description = "ARN del role de ejecución"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "ARN del role del task"
  value       = aws_iam_role.ecs_task.arn
}
