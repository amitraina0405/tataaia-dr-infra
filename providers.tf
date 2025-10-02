##############################################
# Terraform Providers for Hybrid Cloud DR
# Tata AIA Life Insurance
##############################################
terraform {
 required_version = ">= 1.6.0"
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = "~> 5.0"
   }
   local = {
     source  = "hashicorp/local"
     version = "~> 2.4"
   }
   null = {
     source  = "hashicorp/null"
     version = "~> 3.2"
   }
   random = {
     source  = "hashicorp/random"
     version = "~> 3.6"
   }
 }
 backend "s3" {
   bucket         = "tataaia-terraform-state"
   key            = "hybrid-dr/terraform.tfstate"
   region         = "ap-south-1"
   dynamodb_table = "tataaia-terraform-locks"
   encrypt        = true
 }
}
# -------------------------------
# AWS Provider (Hybrid Cloud DR)
# -------------------------------
provider "aws" {
 region  = var.aws_region
 profile = var.aws_profile
}
# -------------------------------
# Local provider (for DR reports)
# -------------------------------
provider "local" {}
# -------------------------------
# Null provider (for Ansible hooks, scripts)
# -------------------------------
provider "null" {}
# -------------------------------
# Random provider (for unique resource names)
# -------------------------------
provider "random" {}
