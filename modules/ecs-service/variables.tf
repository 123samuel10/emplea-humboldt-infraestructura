variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "service_name" {
  description = "Nombre del microservicio"
  type        = string
}

variable "cluster_id" {
  description = "ID del cluster ECS"
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
}

variable "container_image" {
  description = "Imagen del contenedor (URI de ECR)"
  type        = string
}

variable "container_port" {
  description = "Puerto del contenedor"
  type        = number
  default     = 8000
}

variable "task_cpu" {
  description = "CPU para el task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memoria para el task en MB"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Número deseado de tareas"
  type        = number
  default     = 2
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del security group para las tareas ECS"
  type        = string
}

variable "target_group_arn" {
  description = "ARN del target group del ALB"
  type        = string
}

variable "log_group_name" {
  description = "Nombre del log group de CloudWatch"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "environment_variables" {
  description = "Variables de entorno para el contenedor"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets desde Secrets Manager (formato: ARN:json_key::)"
  type        = map(string)
  default     = {}
}

variable "secrets_manager_arns" {
  description = "ARNs de los secrets en Secrets Manager a los que el task necesita acceder"
  type        = list(string)
  default     = []
}

variable "health_check_command" {
  description = "Comando para health check del contenedor"
  type        = list(string)
  default     = null
}

variable "enable_execute_command" {
  description = "Habilitar ECS Exec para debugging"
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "Habilitar auto scaling"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Capacidad mínima para auto scaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Capacidad máxima para auto scaling"
  type        = number
  default     = 6
}

variable "cpu_target_value" {
  description = "Target value de CPU para auto scaling (%)"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target value de memoria para auto scaling (%)"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}
