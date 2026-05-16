variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "microservices" {
  description = "Set de nombres de microservicios"
  type        = set(string)
}
