output "db_endpoint" {
  description = "Endpoint de conexión al RDS (host)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Puerto de conexión al RDS"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Nombre de la base de datos principal"
  value       = aws_db_instance.main.db_name
}

output "master_user_secret_arn" {
  description = "ARN del secret en Secrets Manager con las credenciales del master user"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "db_instance_id" {
  description = "ID de la instancia RDS"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "ARN de la instancia RDS"
  value       = aws_db_instance.main.arn
}
