# terraform/outputs.tf

# ── VPC ──────────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# ── EKS ──────────────────────────────────────────────────────────────────────
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "ecr_backend_url" {
  description = "ECR URL for the backend image"
  value       = module.eks.ecr_backend_url
}

output "ecr_frontend_url" {
  description = "ECR URL for the frontend image"
  value       = module.eks.ecr_frontend_url
}

# ── RDS ──────────────────────────────────────────────────────────────────────
output "db_cluster_endpoint" {
  description = "Aurora MySQL writer endpoint"
  value       = module.rds.db_cluster_endpoint
}

output "db_cluster_reader_endpoint" {
  description = "Aurora MySQL reader endpoint"
  value       = module.rds.db_cluster_reader_endpoint
}

output "db_name" {
  description = "Database name"
  value       = module.rds.db_name
}

output "db_port" {
  description = "Database port"
  value       = module.rds.db_port
}
