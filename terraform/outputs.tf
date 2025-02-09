output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.vpc01.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.subnet01.id
}

output "private_subnet_id_1" {
  description = "ID of the first private subnet (AZ: us-east-1a)"
  value       = aws_subnet.subnet02.id
}

output "private_subnet_id_2" {
  description = "ID of the second private subnet (AZ: us-east-1b)"
  value       = aws_subnet.subnet03.id
}

output "api_instance_id" {
  description = "ID of the EC2 instance for the backend API"
  value       = aws_instance.api_instance01.id
}

output "api_instance_private_ip" {
  description = "Private IP address of the EC2 instance for the backend API"
  value       = aws_instance.api_instance01.private_ip
}

output "redis_instance_id" {
  description = "ID of the EC2 instance for self-managed Redis"
  value       = aws_instance.redis_instance.id
}

output "redis_instance_private_ip" {
  description = "Private IP address of the EC2 instance for self-managed Redis"
  value       = aws_instance.redis_instance.private_ip
}

output "hashicorp_server_id" {
  description = "ID of the EC2 instance for Consul, Nomad, and Vault"
  value       = aws_instance.hashicorp_server.id
}

output "hashicorp_server_private_ip" {
  description = "Private IP address of the EC2 instance for Consul, Nomad, and Vault"
  value       = aws_instance.hashicorp_server.private_ip
}

output "jumphost_id" {
  description = "ID of the Jump Host EC2 instance"
  value       = aws_instance.jumphost.id
}

output "jumphost_public_ip" {
  description = "Public IP address of the Jump Host"
  value       = aws_instance.jumphost.public_ip
}

# The following outputs for RDS and Elasticache are disabled due to insufficient permissions
# and contradictory assignment instructions (RDBMS is deployed on-prem).
#
# output "rds_endpoint" {
#   description = "Endpoint of the RDS instance (PostgreSQL)"
#   value       = aws_db_instance.db_instance01.endpoint
# }
#
# output "redis_endpoint" {
#   description = "Endpoint of the Redis cluster (Elasticache)"
#   value       = aws_elasticache_cluster.cache_cluster01.cache_nodes[0].address
# }
