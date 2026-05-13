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

variable "branch_name" {
  description = "Rama del repositorio a desplegar"
  type        = string
  default     = "main"
}

variable "api_gateway_url" {
  description = "URL del API Gateway para inyectar en el frontend"
  type        = string
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}
