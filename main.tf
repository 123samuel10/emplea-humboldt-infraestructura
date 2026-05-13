locals {
  # Base de datos asignada a cada microservicio
  service_db_names = {
    autenticacion         = "auth_db"
    empleos               = "emp_db"
    postulaciones         = "post_db"
    seguimiento_practicas = "pra_db"
    notificaciones        = "noti_db"
  }
}

# ECR Repositories
module "ecr" {
  source = "./modules/ecr"

  project_name              = var.project_name
  microservices             = toset(keys(var.microservices))
  image_tag_mutability      = "MUTABLE"
  scan_on_push              = true
  enable_lifecycle_policy   = true
  max_image_count           = 10
  enable_cross_account_access = false

  tags = var.tags
}

# VPC
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway = true

  tags = var.tags
}

# Security Groups
module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id

  tags = var.tags
}

# ECS Cluster
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  project_name              = var.project_name
  enable_container_insights = true
  log_retention_days        = 30

  tags = var.tags
}

# Application Load Balancer (subnet pública)
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id

  services = {
    for service_name, config in var.microservices :
    service_name => {
      port              = config.container_port
      health_check_path = config.health_check_path
      priority          = index(keys(var.microservices), service_name) + 1
    }
  }

  enable_deletion_protection = false

  tags = var.tags
}

# RDS PostgreSQL (subnet privada)
module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_id     = module.security_groups.rds_security_group_id
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  tags = var.tags
}

# ECS Services (subnet privada, Fargate)
module "ecs_services" {
  source   = "./modules/ecs-service"
  for_each = var.microservices

  project_name    = var.project_name
  service_name    = each.key
  cluster_id      = module.ecs_cluster.cluster_id
  cluster_name    = module.ecs_cluster.cluster_name
  container_image = each.value.container_image
  container_port  = each.value.container_port
  task_cpu        = each.value.cpu
  task_memory     = each.value.memory
  desired_count   = each.value.desired_count

  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security_groups.ecs_tasks_security_group_id
  target_group_arn   = module.alb.target_group_arns[each.key]

  log_group_name = module.ecs_cluster.log_group_name
  aws_region     = var.aws_region

  environment_variables = merge(each.value.environment_vars, {
    DB_HOST = module.rds.db_endpoint
    DB_PORT = "5432"
    DB_NAME = local.service_db_names[each.key]
  })

  secrets = {
    DB_PASSWORD = "${module.rds.master_user_secret_arn}:password::"
    DB_USER     = "${module.rds.master_user_secret_arn}:username::"
  }

  secrets_manager_arns = [module.rds.master_user_secret_arn]

  enable_autoscaling  = var.enable_autoscaling
  min_capacity        = var.min_capacity
  max_capacity        = var.max_capacity
  cpu_target_value    = 70
  memory_target_value = 80

  tags = var.tags

  depends_on = [module.alb, module.rds]
}

# API Gateway
module "api_gateway" {
  source = "./modules/api-gateway"

  project_name = var.project_name
  stage_name   = var.api_stage_name
  alb_dns_name = module.alb.alb_dns_name

  services = {
    for service_name in keys(var.microservices) :
    service_name => {}
  }

  enable_xray_tracing    = false
  log_retention_days     = 30
  logging_level          = "INFO"
  enable_data_trace      = false
  throttling_burst_limit = 5000
  throttling_rate_limit  = 10000
  enable_cors            = true

  tags = var.tags

  depends_on = [module.alb, module.ecs_services]
}

# Amplify (Frontend NextJS)
module "amplify" {
  source = "./modules/amplify"

  project_name     = var.project_name
  repository_url   = var.amplify_repository
  github_token     = var.amplify_github_token
  branch_name      = var.amplify_branch
  api_gateway_url  = module.api_gateway.api_endpoint

  tags = var.tags

  depends_on = [module.api_gateway]
}
