output "repository_urls" {
  description = "URLs de los repositorios ECR"
  value       = { for k, v in aws_ecr_repository.microservices : k => v.repository_url }
}

output "repository_arns" {
  description = "ARNs de los repositorios ECR"
  value       = { for k, v in aws_ecr_repository.microservices : k => v.arn }
}

output "registry_id" {
  description = "ID del registro ECR"
  value       = values(aws_ecr_repository.microservices)[0].registry_id
}

output "repository_names" {
  description = "Nombres de los repositorios ECR"
  value       = { for k, v in aws_ecr_repository.microservices : k => v.name }
}
