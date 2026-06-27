# ── VPC Outputs ───────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# ── EKS Outputs ───────────────────────────────────────────────────────────────
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "ecr_frontend_url" {
  description = "ECR repository URL for the frontend image"
  value       = module.eks.ecr_frontend_url
}

output "ecr_backend_url" {
  description = "ECR repository URL for the backend image"
  value       = module.eks.ecr_backend_url
}
