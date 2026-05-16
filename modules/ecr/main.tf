resource "aws_ecr_repository" "microservices" {
  for_each = var.microservices

  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
