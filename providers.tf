terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
# Optional: enable backend S3/Dynamo for locking in prod (uncomment & set values)
# terraform {
#   backend "s3" {
#     bucket         = "tata-aia-dr-tfstate"
#     key            = "envs/prod/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "tata-aia-tf-locks"
#     encrypt        = true
#   }
# }
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}