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
