variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "microservices" {
  description = "Set de nombres de microservicios"
  type        = set(string)
}

variable "image_tag_mutability" {
  description = "Mutabilidad de tags de imagen (MUTABLE o IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Habilitar escaneo de vulnerabilidades al subir imagen"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Tipo de encriptación (AES256 o KMS)"
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "ARN de la clave KMS (solo si encryption_type es KMS)"
  type        = string
  default     = null
}

variable "enable_lifecycle_policy" {
  description = "Habilitar política de lifecycle para limpiar imágenes antiguas"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Número máximo de imágenes a mantener"
  type        = number
  default     = 10
}

variable "enable_cross_account_access" {
  description = "Habilitar acceso cross-account"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}
