# ─────────────────────────────────────────────────────────────────────────────
# Book Review App — Terraform Entry Point
# Orchestrates VPC, EKS, and RDS modules
# ─────────────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# EKS module — added in Phase 3
# module "eks" {
#   source = "./modules/eks"
#   ...
# }

# RDS module — added in Phase 4
# module "rds" {
#   source = "./modules/rds"
#   ...
# }
