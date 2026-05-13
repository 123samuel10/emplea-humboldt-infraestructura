variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subnets privadas para RDS"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del security group para RDS"
  type        = string
}

variable "instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Almacenamiento inicial en GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Almacenamiento máximo para autoscaling en GB"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}
