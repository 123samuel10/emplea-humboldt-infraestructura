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
  description = "Imagen del contenedor"
  type        = string
}

variable "container_port" {
  description = "Puerto del contenedor"
  type        = number
}

variable "task_cpu" {
  description = "CPU para el task"
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
  default     = 1
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del security group"
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
  description = "Variables de entorno"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets desde Secrets Manager"
  type        = map(string)
  default     = {}
}

variable "secrets_manager_arns" {
  description = "ARNs de los secrets en Secrets Manager"
  type        = list(string)
  default     = []
}
