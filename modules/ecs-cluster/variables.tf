variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "enable_container_insights" {
  description = "Habilitar Container Insights en CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}
