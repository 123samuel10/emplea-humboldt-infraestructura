variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "emplea-humboldt"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "microservices" {
  description = "Configuración de los microservicios"
  type = map(object({
    container_image   = string
    container_port    = number
    cpu               = string
    memory            = string
    desired_count     = number
    health_check_path = string
    environment_vars  = map(string)
  }))
  default = {
    autenticacion = {
      container_image   = "nginx:latest"
      container_port    = 8000
      cpu               = "256"
      memory            = "512"
      desired_count     = 1
      health_check_path = "/health"
      environment_vars = {
        NODE_ENV = "production"
      }
    }
    empleos = {
      container_image   = "nginx:latest"
      container_port    = 8001
      cpu               = "256"
      memory            = "512"
      desired_count     = 1
      health_check_path = "/health"
      environment_vars = {
        NODE_ENV = "production"
      }
    }
    postulaciones = {
      container_image   = "nginx:latest"
      container_port    = 8002
      cpu               = "256"
      memory            = "512"
      desired_count     = 1
      health_check_path = "/health"
      environment_vars = {
        NODE_ENV = "production"
      }
    }
    seguimiento_practicas = {
      container_image   = "nginx:latest"
      container_port    = 8003
      cpu               = "256"
      memory            = "512"
      desired_count     = 1
      health_check_path = "/health"
      environment_vars = {
        NODE_ENV = "production"
      }
    }
    notificaciones = {
      container_image   = "nginx:latest"
      container_port    = 8004
      cpu               = "256"
      memory            = "512"
      desired_count     = 1
      health_check_path = "/health"
      environment_vars = {
        NODE_ENV = "production"
      }
    }
  }
}

# Amplify
variable "amplify_repository" {
  description = "URL del repositorio GitHub del frontend NextJS"
  type        = string
}

variable "amplify_github_token" {
  description = "GitHub personal access token para Amplify"
  type        = string
  sensitive   = true
}
