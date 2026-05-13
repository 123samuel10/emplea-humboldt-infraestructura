variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "stage_name" {
  description = "Nombre del stage (prd)"
  type        = string
  default     = "prd"
}

variable "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  type        = string
}

variable "services" {
  description = "Configuración de los servicios para API Gateway"
  type        = map(object({}))
}

variable "enable_xray_tracing" {
  description = "Habilitar X-Ray tracing"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Días de retención de logs"
  type        = number
  default     = 30
}

variable "logging_level" {
  description = "Nivel de logging (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}

variable "enable_data_trace" {
  description = "Habilitar data trace en logs"
  type        = bool
  default     = false
}

variable "throttling_burst_limit" {
  description = "Burst limit para throttling"
  type        = number
  default     = 5000
}

variable "throttling_rate_limit" {
  description = "Rate limit para throttling (requests por segundo)"
  type        = number
  default     = 10000
}

variable "enable_cors" {
  description = "Habilitar CORS en respuestas de error"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}
