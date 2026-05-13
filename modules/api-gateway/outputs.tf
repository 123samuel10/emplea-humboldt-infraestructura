output "api_id" {
  description = "ID de la API Gateway"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_endpoint" {
  description = "Endpoint de la API Gateway"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_arn" {
  description = "ARN de la API Gateway"
  value       = aws_api_gateway_rest_api.main.arn
}

output "stage_name" {
  description = "Nombre del stage"
  value       = aws_api_gateway_stage.main.stage_name
}
