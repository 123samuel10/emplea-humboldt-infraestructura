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
  default     = ["us-east-1a"]
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

variable "enable_autoscaling" {
  description = "Habilitar auto scaling para los servicios ECS"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Capacidad mínima para auto scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Capacidad máxima para auto scaling"
  type        = number
  default     = 2
}

variable "api_stage_name" {
  description = "Nombre del stage de API Gateway"
  type        = string
  default     = "prd"
}

# RDS
variable "rds_instance_class" {
  description = "Clase de instancia RDS PostgreSQL"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Almacenamiento inicial en GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Almacenamiento máximo para autoscaling en GB"
  type        = number
  default     = 100
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

variable "amplify_branch" {
  description = "Rama del repositorio a desplegar en producción"
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Project     = "EmpleaHumboldt"
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}
