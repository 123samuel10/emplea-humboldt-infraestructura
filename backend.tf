terraform {
  backend "s3" {
    bucket         = "emplea-humboldt-terraform-state"
    key            = "prd/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "emplea-humboldt-terraform-locks"
    encrypt        = true
  }
}
