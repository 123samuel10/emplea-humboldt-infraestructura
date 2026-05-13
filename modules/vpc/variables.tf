variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para subnets privadas"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}
