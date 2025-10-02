########################################################
# terraform/hybrid-dr/main.tf
# Hybrid DR - AWS resources (VPC, Subnets, EC2, RDS, S3, IAM, CloudWatch)
# Designed for Tata AIA Hybrid-Cloud DR site
########################################################
terraform {
 required_version = ">= 1.0"
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = ">= 4.0"
   }
 }
}
provider "aws" {
 region = var.aws_region
 # credentials are provided via environment / profile / shared credentials file
 # profile = var.aws_profile (optional)
}
####################
# Locals / Tags
####################
locals {
 common_tags = merge({
   Project = "Hybrid-DR"
   Owner   = "TataAIA"
   Env     = "dr"
 }, var.extra_tags)
}
####################
# VPC + Networking
####################
resource "aws_vpc" "dr_vpc" {
 cidr_block           = var.vpc_cidr
 enable_dns_hostnames = true
 enable_dns_support   = true
 tags                 = merge(local.common_tags, { Name = var.dr_vpc_name })
}
resource "aws_internet_gateway" "dr_igw" {
 vpc_id = aws_vpc.dr_vpc.id
 tags   = merge(local.common_tags, { Name = "${var.dr_vpc_name}-igw" })
}
resource "aws_subnet" "dr_public" {
 for_each = toset(var.azs)
 vpc_id            = aws_vpc.dr_vpc.id
 cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key))
 availability_zone = each.key
 map_public_ip_on_launch = true
 tags = merge(local.common_tags, { Name = "${var.dr_vpc_name}-public-${each.key}" })
}
resource "aws_subnet" "dr_private" {
 for_each = toset(var.azs)
 vpc_id            = aws_vpc.dr_vpc.id
 cidr_block        = cidrsubnet(var.vpc_cidr, 8, length(var.azs) + index(var.azs, each.key))
 availability_zone = each.key
 map_public_ip_on_launch = false
 tags = merge(local.common_tags, { Name = "${var.dr_vpc_name}-private-${each.key}" })
}
resource "aws_route_table" "public_rt" {
 vpc_id = aws_vpc.dr_vpc.id
 tags   = merge(local.common_tags, { Name = "${var.dr_vpc_name}-public-rt" })
}
resource "aws_route" "public_internet_access" {
 route_table_id         = aws_route_table.public_rt.id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id             = aws_internet_gateway.dr_igw.id
}
resource "aws_route_table_association" "public_assoc" {
 for_each       = aws_subnet.dr_public
 subnet_id      = each.value.id
 route_table_id = aws_route_table.public_rt.id
}
####################
# Security Group
####################
resource "aws_security_group" "dr_sg" {
 name   = "${var.dr_vpc_name}-sg"
 vpc_id = aws_vpc.dr_vpc.id
 description = "DR SG: allow SSH from management & allow app/DB ports from TN/OnPrem or specific CIDRs"
 dynamic "ingress" {
   for_each = var.sg_ingress_cidrs
   content {
     description = "management access"
     from_port   = lookup(ingress.value, "from_port", 22)
     to_port     = lookup(ingress.value, "to_port", 22)
     protocol    = lookup(ingress.value, "protocol", "tcp")
     cidr_blocks = [lookup(ingress.value, "cidr", ingress.value)]
   }
 }
 # allow replication DB traffic inside VPC
 ingress {
   from_port   = 3306
   to_port     = 3306
   protocol    = "tcp"
   cidr_blocks = [aws_vpc.dr_vpc.cidr_block]
   description = "internal DB replication"
 }
 egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
 tags = merge(local.common_tags, { Name = "${var.dr_vpc_name}-sg" })
}
####################
# IAM Role for EC2 (S3, CloudWatch Logs)
####################
resource "aws_iam_role" "ec2_role" {
 name = "${var.dr_vpc_name}-ec2-role"
 assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
 tags = local.common_tags
}
data "aws_iam_policy_document" "ec2_assume_role" {
 statement {
   actions = ["sts:AssumeRole"]
   principals {
     type        = "Service"
     identifiers = ["ec2.amazonaws.com"]
   }
 }
}
resource "aws_iam_policy" "ec2_s3_cloudwatch_policy" {
 name        = "${var.dr_vpc_name}-ec2-s3-cw-policy"
 description = "Allow EC2 to put logs to CloudWatch and access S3 DR backups"
 policy = jsonencode({
   Version = "2012-10-17",
   Statement = [
     {
       Action = [
         "logs:CreateLogGroup",
         "logs:CreateLogStream",
         "logs:PutLogEvents",
         "logs:DescribeLogStreams"
       ],
       Effect   = "Allow",
       Resource = "*"
     },
     {
       Action = [
         "s3:GetObject",
         "s3:PutObject",
         "s3:ListBucket"
       ],
       Effect   = "Allow",
       Resource = [
         aws_s3_bucket.dr_backups.arn,
         "${aws_s3_bucket.dr_backups.arn}/*"
       ]
     }
   ]
 })
}
resource "aws_iam_role_policy_attachment" "ec2_attach" {
 role       = aws_iam_role.ec2_role.name
 policy_arn = aws_iam_policy.ec2_s3_cloudwatch_policy.arn
}
resource "aws_iam_instance_profile" "ec2_instance_profile" {
 name = "${var.dr_vpc_name}-instance-profile"
 role = aws_iam_role.ec2_role.name
}
####################
# S3 Bucket for Backups
####################
resource "aws_s3_bucket" "dr_backups" {
 bucket = var.s3_backup_bucket_name
 acl    = "private"
 versioning {
   enabled = true
 }
 server_side_encryption_configuration {
   rule {
     apply_server_side_encryption_by_default {
       sse_algorithm = "AES256"
     }
   }
 }
 tags = merge(local.common_tags, { Name = "${var.s3_backup_bucket_name}" })
}
resource "aws_s3_bucket_public_access_block" "dr_backups_block" {
 bucket = aws_s3_bucket.dr_backups.id
 block_public_acls       = true
 block_public_policy     = true
 ignore_public_acls      = true
 restrict_public_buckets = true
}
####################
# EBS Volume for DR data (example)
####################
resource "aws_ebs_volume" "dr_data_volume" {
 availability_zone = element(var.azs, 0)
 size              = var.ebs_size_gb
 type              = var.ebs_type
 encrypted         = true
 tags              = merge(local.common_tags, { Name = "${var.dr_vpc_name}-data-volume" })
}
####################
# EC2 Instances (DR compute)
####################
data "aws_ami" "amazon_linux_2" {
 most_recent = true
 owners      = ["amazon"]
 filter {
   name   = "name"
   values = ["amzn2-ami-hvm-*-x86_64-gp2"]
 }
}
resource "aws_instance" "dr_ec2" {
 count         = var.dr_ec2_count
 ami           = data.aws_ami.amazon_linux_2.id
 instance_type = var.instance_type
 subnet_id     = element(values(aws_subnet.dr_public)[*].id, count.index % length(var.azs))
 vpc_security_group_ids = [aws_security_group.dr_sg.id]
 key_name      = var.ssh_key_name
 iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
 root_block_device {
   volume_size = var.root_volume_size_gb
   volume_type = "gp3"
   delete_on_termination = true
 }
 tags = merge(local.common_tags, { Name = "${var.dr_vpc_name}-ec2-${count.index + 1}" })
 user_data = templatefile("${path.module}/userdata/dr_instance_userdata.sh.tpl", {
   s3_bucket = aws_s3_bucket.dr_backups.bucket,
   region    = var.aws_region
 })
}
# Attach EBS to the first DR instance (example)
resource "aws_volume_attachment" "attach_data_vol" {
 device_name = var.dr_data_device_name
 volume_id   = aws_ebs_volume.dr_data_volume.id
 instance_id = element(aws_instance.dr_ec2.*.id, 0)
 force_detach = true
}
####################
# RDS (MySQL) - Optionally a read replica if `replica_source_identifier` provided
####################
resource "aws_db_subnet_group" "dr_db_subnet_group" {
 name       = "${var.dr_vpc_name}-db-subnet-group"
 subnet_ids = values(aws_subnet.dr_private)[*].id
 tags       = local.common_tags
}
resource "aws_db_instance" "dr_rds" {
 count                     = var.create_rds ? 1 : 0
 identifier                = "${var.dr_vpc_name}-rds"
 engine                    = var.rds_engine
 engine_version            = var.rds_engine_version
 instance_class            = var.rds_instance_class
 allocated_storage         = var.rds_allocated_storage
 username                  = var.rds_master_username
 password                  = var.rds_master_password
 db_subnet_group_name      = aws_db_subnet_group.dr_db_subnet_group.name
 vpc_security_group_ids    = [aws_security_group.dr_sg.id]
 publicly_accessible       = false
 skip_final_snapshot       = true
 storage_encrypted         = true
 backup_retention_period   = var.rds_backup_retention_days
 tags                      = local.common_tags
 # If replica_source_identifier is defined, create a read-replica by referencing source db ARN
 replicate_source_db = var.rds_replicate_source_db != "" ? var.rds_replicate_source_db : null
}
####################
# CloudWatch Log Group & Simple Alarm
####################
resource "aws_cloudwatch_log_group" "dr_log_group" {
 name              = "/aws/dr/validation"
 retention_in_days = 14
 tags              = local.common_tags
}
resource "aws_cloudwatch_metric_alarm" "dr_instance_cpu_high" {
 alarm_name          = "${var.dr_vpc_name}-ec2-cpu-high"
 comparison_operator = "GreaterThanThreshold"
 evaluation_periods  = 2
 metric_name         = "CPUUtilization"
 namespace           = "AWS/EC2"
 period              = 300
 statistic           = "Average"
 threshold           = var.alarm_cpu_threshold
 alarm_description   = "Alarm when DR EC2 CPU is high"
 dimensions = {
   AutoScalingGroupName = "" # if ASG used override; otherwise dimensions not required
 }
 # Simple action: send to SNS topic if provided
 alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
 ok_actions    = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
 tags = local.common_tags
}
####################
# Outputs
####################
output "dr_vpc_id" {
 value = aws_vpc.dr_vpc.id
 description = "DR VPC id"
}
output "dr_public_subnet_ids" {
 value = values(aws_subnet.dr_public)[*].id
 description = "List of public subnet ids"
}
output "dr_private_subnet_ids" {
 value = values(aws_subnet.dr_private)[*].id
 description = "List of private subnet ids"
}
output "dr_ec2_public_ips" {
 value = aws_instance.dr_ec2[*].public_ip
 description = "Public IPs of DR EC2 instances (if map_public_ip_on_launch true)"
}
output "dr_ec2_ids" {
 value = aws_instance.dr_ec2[*].id
 description = "IDs of DR EC2 instances"
}
output "dr_ebs_volume_id" {
 value = aws_ebs_volume.dr_data_volume.id
 description = "EBS volume id for DR data"
}
output "dr_rds_endpoint" {
 value = length(aws_db_instance.dr_rds) > 0 ? aws_db_instance.dr_rds[0].address : ""
 description = "RDS endpoint if created"
}
output "dr_backups_s3_bucket" {
 value = aws_s3_bucket.dr_backups.bucket
 description = "S3 bucket used to store backups for DR"
}
