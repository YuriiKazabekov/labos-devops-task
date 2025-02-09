# AWS region for deploying resources
variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "us-east-1"
}

# CIDR block for the VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# CIDR block for the public subnet
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# CIDR block for the first private subnet (AZ: us-east-1a)
variable "private_subnet_cidr" {
  description = "CIDR block for the first private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# CIDR block for the second private subnet (AZ: us-east-1b)
variable "private_subnet_cidr2" {
  description = "CIDR block for the second private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# EC2 Key Pair name for SSH access
variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = "labos-keypair-01" 
}

# EC2 instance type for the backend API
variable "instance_type" {
  description = "EC2 instance type for the backend API"
  type        = string
  default     = "t3.micro"
}

# RDS (PostgreSQL) variables
variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "labosdb01"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS (in GB)"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "13.4"
}

# Redis (Elasticache) variables
variable "redis_node_type" {
  description = "Instance type for Elasticache Redis"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "6.x"
}
