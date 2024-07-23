# Dynamically Generated Files
# Keep provider dry and reuse default_tags
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  allowed_account_ids = [""]
}
EOF
}


# Inject default_tags var
generate "vars" {
  path      = "vars.g.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "default_tags" {
  type = map(any)
}

variable "project" {
  type = object({
    name = string
    environment = string
  })
}
EOF
}