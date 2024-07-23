locals {
  globals = yamldecode(file("../../globals.yaml"))
  name            = "lapalma"
  environment     = "prod"
  generated_files = read_terragrunt_config("${path_relative_from_include()}/generated.hcl")
}

generate = local.generated_files.generate

inputs = {
  project = {
    name        = local.name
    environment = local.environment
  }

  default_tags = {
    Project     = local.name
    Environment = local.environment
    Repo        = "${local.globals.infraSourceConfig.owner}/${local.globals.infraSourceConfig.name}"
  }
}

remote_state {
  backend = "s3"
  config = {
    encrypt = true
    bucket  = "lapalma-terraform-state"
    key     = "infra-${local.globals.project.name}/${local.globals.project.environment}/${path_relative_to_include()}/terraform.tfstate"
    region  = "us-east-1"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}