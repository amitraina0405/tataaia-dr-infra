#########################################
# Terraform Variables for Hybrid DR
# Tata AIA Life Insurance
#########################################
# -------------------------------
# AWS Provider Variables
# -------------------------------
variable "aws_region" {
 description = "AWS region for DR deployment"
 type        = string
 default     = "ap-south-1"
}
variable "aws_profile" {
 description = "AWS CLI profile name (optional)"
 type        = string
 default     = ""
}
# -------------------------------
# Environment / Project
# -------------------------------
variable "environment" {
 description = "Environment name (prod/dev/uat)"
 type        = string
 default     = "prod"
}
variable "project_name" {
 description = "Project name"
 type        = string
 default     = "tataaia-hybrid-dr"
}
# -------------------------------
# Networking / VPC
# -------------------------------
variable "vpc_cidr" {
 description = "CIDR block for DR VPC"
 type        = string
 default     = "10.50.0.0/16"
}
variable "availability_zones" {
 description = "List of AZs for DR deployment"
 type        = list(string)
 default     = ["ap-south-1a", "ap-south-1b"]
}
variable "public_subnets" {
 description = "List of public subnet CIDRs"
 type        = list(string)
 default     = ["10.50.1.0/24", "10.50.2.0/24"]
}
variable "private_subnets" {
 description = "List of private subnet CIDRs"
 type        = list(string)
 default     = ["10.50.10.0/24", "10.50.20.0/24"]
}
# -------------------------------
# EC2 Instances (DR Servers)
# -------------------------------
variable "ec2_instance_type" {
 description = "EC2 instance type for DR servers"
 type        = string
 default     = "t3.large"
}
variable "ec2_key_name" {
 description = "SSH Key name for DR EC2"
 type        = string
 default     = "tataaia-dr-key"
}
variable "ec2_instance_count" {
 description = "Number of DR EC2 instances"
 type        = number
 default     = 3
}
variable "ec2_ami_id" {
 description = "AMI ID for DR EC2 instances"
 type        = string
 default     = "" # Set production AMI ID in tfvars
}
# -------------------------------
# Security Group / Firewall
# -------------------------------
variable "allowed_ssh_cidr" {
 description = "CIDR allowed for SSH to DR servers"
 type        = list(string)
 default     = ["10.10.0.0/16"]
}
variable "allowed_https_cidr" {
 description = "CIDR allowed for HTTPS to DR servers"
 type        = list(string)
 default     = ["0.0.0.0/0"]
}
# -------------------------------
# RDS / Database
# -------------------------------
variable "create_rds" {
 description = "Whether to create DR RDS instance"
 type        = bool
 default     = true
}
variable "rds_engine" {
 description = "RDS Engine (mysql/postgres)"
 type        = string
 default     = "mysql"
}
variable "rds_engine_version" {
 description = "RDS Engine Version"
 type        = string
 default     = "8.0"
}
variable "rds_instance_class" {
 description = "RDS Instance Type"
 type        = string
 default     = "db.m5.large"
}
variable "rds_allocated_storage" {
 description = "RDS storage in GB"
 type        = number
 default     = 100
}
variable "rds_db_name" {
 description = "RDS Database Name"
 type        = string
 default     = "drdb"
}
variable "rds_username" {
 description = "RDS Master Username"
 type        = string
 default     = "dradmin"
}
variable "rds_password" {
 description = "RDS Master Password (use Vault or tfvars)"
 type        = string
 default     = ""
 sensitive   = true
}
variable "rds_multi_az" {
 description = "Enable Multi-AZ deployment for RDS"
 type        = bool
 default     = true
}
variable "rds_backup_retention" {
 description = "Backup retention period in days"
 type        = number
 default     = 7
}
# -------------------------------
# S3 Buckets
# -------------------------------
variable "dr_backup_bucket_name" {
 description = "S3 Bucket name for DR backups"
 type        = string
 default     = ""
}
variable "dr_logs_bucket_name" {
 description = "S3 Bucket name for DR logs"
 type        = string
 default     = ""
}
# -------------------------------
# IAM Role
# -------------------------------
variable "dr_iam_role_name" {
 description = "IAM role for DR automation"
 type        = string
 default     = "tataaia-dr-automation-role"
}
# -------------------------------
# Load Balancer / Networking
# -------------------------------
variable "alb_name" {
 description = "Application Load Balancer name for DR"
 type        = string
 default     = ""
}
variable "alb_internal" {
 description = "Whether the ALB is internal"
 type        = bool
 default     = false
}
# -------------------------------
# Monitoring / CloudWatch
# -------------------------------
variable "enable_cloudwatch" {
 description = "Enable CloudWatch monitoring and alarms"
 type        = bool
 default     = true
}
variable "alarm_cpu_threshold" {
 description = "CPU threshold (%) for CloudWatch alarm"
 type        = number
 default     = 75
}
variable "alarm_memory_threshold" {
 description = "Memory threshold (%) for CloudWatch alarm"
 type        = number
 default     = 80
}
# -------------------------------
# Tags / Metadata
# -------------------------------
variable "tags" {
 description = "Custom tags for all resources"
 type        = map(string)
 default     = {
   Environment = "prod"
   Project     = "Hybrid-DR"
   Owner       = "SRE-Team"
   Compliance  = "ISO22301"
 }
}
