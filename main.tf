locals {
 name = "${var.project}-${var.environment}"
}
# ========== VPCs & Subnets ==========
resource "aws_vpc" "primary" {
 provider             = aws.primary
 cidr_block           = var.primary_vpc_cidr
 enable_dns_support   = true
 enable_dns_hostnames = true
 tags = merge(var.tags, { Name = "${local.name}-primary-vpc" })
}
resource "aws_vpc" "dr" {
 provider             = aws.dr
 cidr_block           = var.dr_vpc_cidr
 enable_dns_support   = true
 enable_dns_hostnames = true
 tags = merge(var.tags, { Name = "${local.name}-dr-vpc" })
}
# create 2 AZ subnets each for app & db (primary)
resource "aws_subnet" "primary_app_a" {
 provider = aws.primary
 vpc_id = aws_vpc.primary.id
 cidr_block = cidrsubnet(var.primary_vpc_cidr, 4, 0)
 tags = merge(var.tags, { Name = "${local.name}-primary-app-a" })
}
resource "aws_subnet" "primary_app_b" {
 provider = aws.primary
 vpc_id = aws_vpc.primary.id
 cidr_block = cidrsubnet(var.primary_vpc_cidr, 4, 1)
 tags = merge(var.tags, { Name = "${local.name}-primary-app-b" })
}
resource "aws_subnet" "primary_db_a" {
 provider = aws.primary
 vpc_id = aws_vpc.primary.id
 cidr_block = cidrsubnet(var.primary_vpc_cidr, 4, 2)
 tags = merge(var.tags, { Name = "${local.name}-primary-db-a" })
}
resource "aws_subnet" "primary_db_b" {
 provider = aws.primary
 vpc_id = aws_vpc.primary.id
 cidr_block = cidrsubnet(var.primary_vpc_cidr, 4, 3)
 tags = merge(var.tags, { Name = "${local.name}-primary-db-b" })
}
# DR subnets
resource "aws_subnet" "dr_app_a" {
 provider = aws.dr
 vpc_id = aws_vpc.dr.id
 cidr_block = cidrsubnet(var.dr_vpc_cidr, 4, 0)
 tags = merge(var.tags, { Name = "${local.name}-dr-app-a" })
}
resource "aws_subnet" "dr_app_b" {
 provider = aws.dr
 vpc_id = aws_vpc.dr.id
 cidr_block = cidrsubnet(var.dr_vpc_cidr, 4, 1)
 tags = merge(var.tags, { Name = "${local.name}-dr-app-b" })
}
resource "aws_subnet" "dr_db_a" {
 provider = aws.dr
 vpc_id = aws_vpc.dr.id
 cidr_block = cidrsubnet(var.dr_vpc_cidr, 4, 2)
 tags = merge(var.tags, { Name = "${local.name}-dr-db-a" })
}
resource "aws_subnet" "dr_db_b" {
 provider = aws.dr
 vpc_id = aws_vpc.dr.id
 cidr_block = cidrsubnet(var.dr_vpc_cidr, 4, 3)
 tags = merge(var.tags, { Name = "${local.name}-dr-db-b" })
}
# Internal NLBs (placeholders for endpoints)
resource "aws_lb" "primary_nlb" {
 provider = aws.primary
 name = "${local.name}-primary-nlb"
 internal = true
 load_balancer_type = "network"
 subnets = [aws_subnet.primary_app_a.id, aws_subnet.primary_app_b.id]
 tags = var.tags
}
resource "aws_lb" "dr_nlb" {
 provider = aws.dr
 name = "${local.name}-dr-nlb"
 internal = true
 load_balancer_type = "network"
 subnets = [aws_subnet.dr_app_a.id, aws_subnet.dr_app_b.id]
 tags = var.tags
}
# ========== Site-to-Site VPN (basic) ==========
resource "aws_customer_gateway" "onprem" {
 provider = aws.primary
 bgp_asn = 65000
 ip_address = var.onprem_public_ip
 type = "ipsec.1"
 tags = merge(var.tags, { Name = "${local.name}-onprem-cgw" })
}
resource "aws_vpn_gateway" "primary" {
 provider = aws.primary
 vpc_id = aws_vpc.primary.id
 tags = merge(var.tags, { Name = "${local.name}-vgw" })
}
resource "aws_vpn_connection" "primary" {
 provider = aws.primary
 vpn_gateway_id = aws_vpn_gateway.primary.id
 customer_gateway_id = aws_customer_gateway.onprem.id
 type = "ipsec.1"
 static_routes_only = true
 tags = merge(var.tags, { Name = "${local.name}-vpn" })
}
resource "aws_vpn_connection_route" "primary_route" {
 provider = aws.primary
 vpn_connection_id = aws_vpn_connection.primary.id
 destination_cidr_block = var.onprem_cidr
}
# ========== S3 cross-region replication ==========
resource "aws_s3_bucket" "primary" {
 provider = aws.primary
 bucket = var.s3_primary_bucket
 acl    = "private"
 versioning { enabled = true }
 server_side_encryption_configuration {
   rule {
     apply_server_side_encryption_by_default {
       sse_algorithm = "AES256"
     }
   }
 }
 tags = var.tags
}
resource "aws_s3_bucket" "dr" {
 provider = aws.dr
 bucket = var.s3_dr_bucket
 acl    = "private"
 versioning { enabled = true }
 server_side_encryption_configuration {
   rule {
     apply_server_side_encryption_by_default {
       sse_algorithm = "AES256"
     }
   }
 }
 tags = var.tags
}
data "aws_iam_policy_document" "s3_assume" {
 statement {
   actions = ["sts:AssumeRole"]
   principals { type = "Service", identifiers = ["s3.amazonaws.com"] }
 }
}
resource "aws_iam_role" "s3_replication_role" {
 provider = aws.primary
 name = "${local.name}-s3-repl-role"
 assume_role_policy = data.aws_iam_policy_document.s3_assume.json
 tags = var.tags
}
data "aws_iam_policy_document" "s3_replication_policy" {
 statement {
   actions = [
     "s3:GetReplicationConfiguration",
     "s3:ListBucket"
   ]
   resources = ["arn:aws:s3:::${var.s3_primary_bucket}"]
 }
 statement {
   actions = [
     "s3:GetObjectVersion",
     "s3:GetObjectVersionAcl",
     "s3:GetObjectVersionTagging"
   ]
   resources = ["arn:aws:s3:::${var.s3_primary_bucket}/*"]
 }
 statement {
   actions = [
     "s3:ReplicateObject",
     "s3:ReplicateDelete",
     "s3:ReplicateTags"
   ]
   resources = ["arn:aws:s3:::${var.s3_dr_bucket}/*"]
 }
}
resource "aws_iam_role_policy" "s3_replication_policy_attach" {
 provider = aws.primary
 role = aws_iam_role.s3_replication_role.id
 policy = data.aws_iam_policy_document.s3_replication_policy.json
}
resource "aws_s3_bucket_replication_configuration" "replication" {
 provider = aws.primary
 bucket = aws_s3_bucket.primary.id
 role   = aws_iam_role.s3_replication_role.arn
 rule {
   id = "replicate-all"
   status = "Enabled"
   destination {
     bucket = aws_s3_bucket.dr.arn
     storage_class = "STANDARD"
   }
 }
}
# ========== RDS primary + cross-region read replica ==========
resource "aws_db_subnet_group" "primary" {
 provider = aws.primary
 name = "${local.name}-db-subnets"
 subnet_ids = [aws_subnet.primary_db_a.id, aws_subnet.primary_db_b.id]
 tags = var.tags
}
resource "aws_db_instance" "primary" {
 provider = aws.primary
 identifier = "${local.name}-primary-db"
 engine = "postgres"
 instance_class = var.db_instance_class
 name = var.db_name
 username = var.db_username
 password = var.db_password
 allocated_storage = var.db_allocated_storage
 multi_az = true
 storage_encrypted = true
 backup_retention_period = 7
 db_subnet_group_name = aws_db_subnet_group.primary.name
 skip_final_snapshot = true
 tags = var.tags
}
# Create an RDS instance in DR region as a read-replica (replicate_source_db uses arn)
resource "aws_db_subnet_group" "dr" {
 provider = aws.dr
 name = "${local.name}-db-subnets-dr"
 subnet_ids = [aws_subnet.dr_db_a.id, aws_subnet.dr_db_b.id]
 tags = var.tags
}
resource "aws_db_instance" "dr_replica" {
 provider = aws.dr
 identifier = "${local.name}-dr-replica"
 replicate_source_db = aws_db_instance.primary.arn
 instance_class = var.db_instance_class
 publicly_accessible = false
 storage_encrypted = true
 db_subnet_group_name = aws_db_subnet_group.dr.name
 tags = var.tags
}
# ========== Route53 failover (primary/secondary) ==========
data "aws_route53_zone" "hosted" {
 provider = aws.primary
 name = var.hosted_zone_name
}
resource "aws_route53_health_check" "primary" {
 provider = aws.primary
 fqdn = aws_lb.primary_nlb.dns_name
 type = "TCP"
 port = 443
 tags = var.tags
}
resource "aws_route53_health_check" "dr" {
 provider = aws.primary
 fqdn = aws_lb.dr_nlb.dns_name
 type = "TCP"
 port = 443
 tags = var.tags
}
resource "aws_route53_record" "app_primary" {
 provider = aws.primary
 zone_id = data.aws_route53_zone.hosted.zone_id
 name    = var.record_fqdn
 type    = "CNAME"
 ttl     = 30
 set_identifier = "primary"
 failover_routing_policy { type = "PRIMARY" }
 records = [aws_lb.primary_nlb.dns_name]
 health_check_id = aws_route53_health_check.primary.id
}
resource "aws_route53_record" "app_dr" {
 provider = aws.primary
 zone_id = data.aws_route53_zone.hosted.zone_id
 name    = var.record_fqdn
 type    = "CNAME"
 ttl     = 30
 set_identifier = "secondary"
 failover_routing_policy { type = "SECONDARY" }
 records = [aws_lb.dr_nlb.dns_name]
 health_check_id = aws_route53_health_check.dr.id
}
# ========== AWS Backup ==========
resource "aws_backup_vault" "vault" {
 provider = aws.primary
 name = "${local.name}-backup-vault"
 tags = var.tags
}
resource "aws_backup_plan" "daily" {
 provider = aws.primary
 name = "${local.name}-daily-7d"
 rule {
   rule_name = "daily"
   target_vault_name = aws_backup_vault.vault.name
   schedule = "cron(0 18 * * ? *)"  # daily (UTC) - adjust for local window
   lifecycle { delete_after = 7 }
 }
}
resource "aws_iam_role" "backup_role" {
 provider = aws.primary
 name = "${local.name}-backup-role"
 assume_role_policy = data.aws_iam_policy_document.backup_assume.json
 tags = var.tags
}
data "aws_iam_policy_document" "backup_assume" {
 statement {
   principals { type = "Service", identifiers = ["backup.amazonaws.com"] }
   actions = ["sts:AssumeRole"]
 }
}
resource "aws_backup_selection" "tagged" {
 provider = aws.primary
 name = "tagged-resources"
 plan_id = aws_backup_plan.daily.id
 iam_role_arn = aws_iam_role.backup_role.arn
 selection_tag {
   type = "STRINGEQUALS"
   key = "backup"
   value = "true"
 }
}
# ========== Monitoring example (CloudWatch alarm on RDS free storage) ==========
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
 provider = aws.primary
 alarm_name = "${local.name}-rds-free-storage-low"
 comparison_operator = "LessThanThreshold"
 evaluation_periods  = 2
 metric_name = "FreeStorageSpace"
 namespace = "AWS/RDS"
 period = 300
 statistic = "Average"
 threshold = 10737418240 # 10 GiB
 alarm_description = "RDS free storage below 10GiB"
 dimensions = {
   DBInstanceIdentifier = aws_db_instance.primary.id
 }
 tags = var.tags
}