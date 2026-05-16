terraform {
  backend "s3" {
    bucket  = "emplea-humboldt-terraform-state"
    key     = "prd/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true

    # ADVERTENCIA: Sin locks, evita ejecutar terraform apply simultáneamente
    # desde múltiples ubicaciones (ej: local + GitHub Actions al mismo tiempo)
  }
}
