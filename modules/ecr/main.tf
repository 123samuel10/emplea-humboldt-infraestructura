resource "aws_ecr_repository" "microservices" {
  for_each = var.microservices

  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name         = "${var.project_name}-${each.key}"
    Microservice = each.key
  })
}

resource "aws_ecr_lifecycle_policy" "microservices" {
  for_each   = var.enable_lifecycle_policy ? var.microservices : toset([])
  repository = aws_ecr_repository.microservices[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantener solo las últimas ${var.max_image_count} imágenes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "microservices" {
  for_each   = var.enable_cross_account_access ? var.microservices : toset([])
  repository = aws_ecr_repository.microservices[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPullFromECS"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}
