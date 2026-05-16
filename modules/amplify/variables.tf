variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "repository_url" {
  description = "URL del repositorio GitHub del frontend"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token para Amplify"
  type        = string
  sensitive   = true
}

variable "api_gateway_url" {
  description = "URL del API Gateway"
  type        = string
}
