variable "project" {
 type = string
 default = "automated-dr-iac-pac-hybrid-cloud"
 description = "Short resource-safe project id for: Automated Disaster Recovery using Infrastructure as Code and Policy as Code in Hybrid Cloud Environment"
}
variable "project_long_name" {
 type    = string
 default = "Automated Disaster Recovery using Infrastructure as Code and Policy as Code in Hybrid Cloud Environment"
 description = "Full project title for reports and documentation"
}
variable "environment" { type = string, default = "tataaia" }
variable "primary_region" { type = string, default = "ap-south-1" }   # primary (example)
variable "dr_region"      { type = string, default = "ap-southeast-1" }# DR (example)
variable "vpc_cidr_primary" { type = string, default = "10.10.0.0/16" }
variable "vpc_cidr_dr"      { type = string, default = "10.20.0.0/16" }
variable "az_count" { type = number, default = 2 }
# Route53 / DNS (optional; leave empty to skip)
variable "route53_zone_id" { type = string, default = "" }
variable "domain_name" { type = string, default = "" }
# Application list (informational)
variable "app_names" { type = list(string), default = ["sellonline","nbt","goodconnect","nvest"] }