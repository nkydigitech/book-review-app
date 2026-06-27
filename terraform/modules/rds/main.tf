# terraform/modules/rds/main.tf
# Phase 4 — Aurora MySQL cluster in private subnets

# --------------------------------------------------
# Security Group — allow MySQL from EKS worker nodes
# --------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow MySQL access from EKS workers"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL from EKS worker nodes"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# --------------------------------------------------
# DB Subnet Group — use private subnets
# --------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Aurora MySQL subnet group — private subnets"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

# --------------------------------------------------
# Aurora MySQL Cluster
# --------------------------------------------------
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.project_name}-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.04.0"
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"

  tags = {
    Name        = "${var.project_name}-aurora-cluster"
    Project     = var.project_name
    Environment = var.environment
  }
}

# --------------------------------------------------
# Aurora Instance (writer)
# --------------------------------------------------
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.project_name}-aurora-writer"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible  = false

  tags = {
    Name        = "${var.project_name}-aurora-writer"
    Project     = var.project_name
    Environment = var.environment
  }
}
