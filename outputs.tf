#######################################
# Terraform Outputs for Hybrid DR Setup
# Tata AIA Life Insurance
#######################################
# Networking
output "vpc_id" {
 description = "The ID of the created VPC"
 value       = aws_vpc.hybrid_dr_vpc.id
}
output "public_subnet_ids" {
 description = "List of public subnet IDs"
 value       = aws_subnet.public[*].id
}
output "private_subnet_ids" {
 description = "List of private subnet IDs"
 value       = aws_subnet.private[*].id
}
output "security_group_id" {
 description = "DR Security Group ID"
 value       = aws_security_group.dr_sg.id
}
# EC2 Instances (DR servers)
output "dr_ec2_instance_ids" {
 description = "IDs of all DR EC2 instances"
 value       = aws_instance.dr_servers[*].id
}
output "dr_ec2_public_ips" {
 description = "Public IPs of DR EC2 instances"
 value       = aws_instance.dr_servers[*].public_ip
}
output "dr_ec2_private_ips" {
 description = "Private IPs of DR EC2 instances"
 value       = aws_instance.dr_servers[*].private_ip
}
# RDS / Database Failover
output "dr_rds_endpoint" {
 description = "Endpoint for the DR RDS instance"
 value       = aws_db_instance.dr_rds.address
}
output "dr_rds_port" {
 description = "Port for the DR RDS instance"
 value       = aws_db_instance.dr_rds.port
}
# S3 Buckets for Backup/Logs
output "dr_backup_bucket" {
 description = "S3 bucket name for DR backups"
 value       = aws_s3_bucket.dr_backup.bucket
}
output "dr_logs_bucket" {
 description = "S3 bucket name for DR logs"
 value       = aws_s3_bucket.dr_logs.bucket
}
# IAM Role for DR Automation
output "dr_iam_role_arn" {
 description = "ARN of the IAM role for DR automation"
 value       = aws_iam_role.dr_role.arn
}
# Load Balancer for Failover
output "dr_alb_dns" {
 description = "DNS name of the DR Application Load Balancer"
 value       = aws_lb.dr_alb.dns_name
}
# CloudWatch / Monitoring
output "cloudwatch_alarm_arns" {
 description = "ARNs of DR CloudWatch alarms"
 value       = aws_cloudwatch_metric_alarm.dr_alarms[*].arn
}
#######################################
# Compliance / Policy as Code Validation
#######################################
output "terraform_plan_file" {
 description = "Terraform plan file for OPA/Conftest validation"
 value       = "${path.module}/plan.json"
}
