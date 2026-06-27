# terraform/modules/rds/outputs.tf

output "db_cluster_endpoint" {
  description = "Writer endpoint for the Aurora cluster"
  value       = aws_rds_cluster.main.endpoint
}

output "db_cluster_reader_endpoint" {
  description = "Reader endpoint for the Aurora cluster"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "db_name" {
  description = "Name of the created database"
  value       = aws_rds_cluster.main.database_name
}

output "db_port" {
  description = "Port the Aurora cluster listens on"
  value       = aws_rds_cluster.main.port
}

output "db_security_group_id" {
  description = "Security group ID attached to the RDS cluster"
  value       = aws_security_group.rds.id
}
