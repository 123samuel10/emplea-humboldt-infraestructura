variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  type        = string
}

variable "services" {
  description = "Configuración de los servicios para API Gateway"
  type        = map(object({}))
}
