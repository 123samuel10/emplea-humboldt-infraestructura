output "vpc_id" {
  description = "ID de la VPC"
  value       = module.vpc.vpc_id
}

output "api_gateway_endpoint" {
  description = "Endpoint de API Gateway"
  value       = module.api_gateway.api_endpoint
}

output "api_gateway_url" {
  description = "URL completa de API Gateway"
  value       = "${module.api_gateway.api_endpoint}/"
}

output "alb_dns_name" {
  description = "DNS del Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = module.ecs_cluster.cluster_name
}

output "microservices_endpoints" {
  description = "Endpoints de cada microservicio via API Gateway"
  value = {
    for service_name in keys(var.microservices) :
    service_name => "${module.api_gateway.api_endpoint}/${service_name}"
  }
}

output "ecr_repository_urls" {
  description = "URLs de los repositorios ECR"
  value       = module.ecr.repository_urls
}

output "ecr_push_commands" {
  description = "Comandos para subir imágenes a ECR"
  value = {
    for service_name, repo_url in module.ecr.repository_urls :
    service_name => [
      "docker build -t ${service_name} ./${service_name}",
      "docker tag ${service_name}:latest ${repo_url}:latest",
      "docker push ${repo_url}:latest"
    ]
  }
}

output "rds_endpoint" {
  description = "Endpoint del RDS PostgreSQL"
  value       = module.rds.db_endpoint
}

output "rds_secret_arn" {
  description = "ARN del secret de credenciales RDS en Secrets Manager"
  value       = module.rds.master_user_secret_arn
}

output "amplify_app_url" {
  description = "URL del frontend en Amplify"
  value       = module.amplify.app_url
}

output "amplify_app_id" {
  description = "ID de la app Amplify"
  value       = module.amplify.app_id
}
