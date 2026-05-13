# Subnet group (subnets privadas)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.project_name}-db-subnet-group" })
}

# Parameter group PostgreSQL 15
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-pg15"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = merge(var.tags, { Name = "${var.project_name}-pg15" })
}

# Instancia RDS PostgreSQL
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  engine_version = "15.7"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # La contraseña la gestiona RDS y la almacena en Secrets Manager automáticamente
  db_name  = "emplea_db"
  username = "empleaadmin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  multi_az = false

  backup_retention_period = 3
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  deletion_protection = false
  skip_final_snapshot = true

  tags = merge(var.tags, { Name = "${var.project_name}-postgres" })
}
