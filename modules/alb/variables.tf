variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subnets públicas para el ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del security group para el ALB"
  type        = string
}

variable "services" {
  description = "Configuración de los servicios"
  type = map(object({
    port              = number
    health_check_path = string
    priority          = number
  }))
}

variable "enable_deletion_protection" {
  description = "Habilitar protección contra eliminación"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}
