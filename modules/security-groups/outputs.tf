output "alb_security_group_id" {
  description = "ID del security group del ALB"
  value       = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "ID del security group de ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "rds_security_group_id" {
  description = "ID del security group de RDS PostgreSQL"
  value       = aws_security_group.rds.id
}

output "vpc_link_security_group_id" {
  description = "ID del security group del VPC Link"
  value       = aws_security_group.vpc_link.id
}
