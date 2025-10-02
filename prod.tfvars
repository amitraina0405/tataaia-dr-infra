#########################################
# Production Variables for Hybrid DR Setup
# Tata AIA Life Insurance - PROD
#########################################
# AWS Region & Environment
aws_region         = "ap-south-1"
environment        = "prod"
project_name       = "tataaia-hybrid-dr"
# Networking
vpc_cidr           = "10.50.0.0/16"
public_subnets     = ["10.50.1.0/24", "10.50.2.0/24"]
private_subnets    = ["10.50.10.0/24", "10.50.20.0/24"]
availability_zones = ["ap-south-1a", "ap-south-1b"]
# EC2 (DR Application Servers)
ec2_instance_type  = "t3.large"
ec2_key_name       = "tataaia-dr-key"
ec2_instance_count = 3
ec2_ami_id         = "ami-0abcdef1234567890"   # Latest hardened AMI for DR servers
# Security Groups
allowed_ssh_cidr   = ["10.10.0.0/16"]  # On-Prem network CIDR
allowed_https_cidr = ["0.0.0.0/0"]
# RDS (Database DR Setup)
rds_engine         = "mysql"
rds_instance_class = "db.m5.large"
rds_allocated_storage = 100
rds_db_name        = "drdb"
rds_username       = "dradmin"
rds_password       = "SuperSecureDRPass123!"   # 🔐 Must be managed via Vault/Secrets Manager
rds_multi_az       = true
rds_backup_retention = 7
# S3 Buckets
dr_backup_bucket_name = "tataaia-dr-backups-prod"
dr_logs_bucket_name   = "tataaia-dr-logs-prod"
# IAM Roles
dr_iam_role_name = "tataaia-dr-automation-role"
# Load Balancer
alb_name         = "tataaia-dr-alb"
alb_internal     = false
# Monitoring
enable_cloudwatch = true
alarm_cpu_threshold = 75
alarm_memory_threshold = 80
# Tags
tags = {
 Environment = "prod"
 Project     = "Hybrid-DR"
 Owner       = "SRE-Team"
 Compliance  = "ISO22301"
}
