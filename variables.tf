variable "project"         { type = string, default = "tata-aia" }
variable "environment"     { type = string, default = "prod" }
variable "primary_region"  { type = string, default = "ap-south-1" }
variable "dr_region"       { type = string, default = "ap-southeast-1" }
variable "primary_vpc_cidr" { type = string, default = "10.10.0.0/16" }
variable "dr_vpc_cidr"      { type = string, default = "10.20.0.0/16" }
variable "onprem_cidr"      { type = string, default = "10.0.0.0/16" }
variable "onprem_public_ip" { type = string, default = "203.0.113.10" } # replace with real on-prem public IP
variable "s3_primary_bucket" { type = string, default = "tata-aia-prod-app-bucket" }
variable "s3_dr_bucket"      { type = string, default = "tata-aia-dr-app-bucket" }
variable "db_name"           { type = string, default = "tata_app" }
variable "db_username"       { type = string, default = "appuser" }
variable "db_password"       { type = string, sensitive = true, default = "ChangeMeNow123!" }
variable "db_instance_class" { type = string, default = "db.m6g.large" }
variable "db_allocated_storage" { type = number, default = 50 }
variable "tags" { type = map(string), default = {
 owner   = "SRE"
 project = "tata-aia"
 env     = "prod"
 cost    = "dr"
 backup  = "true"
} }