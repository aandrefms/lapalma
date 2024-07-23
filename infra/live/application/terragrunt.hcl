terraform {
  source ="../../modules/ec2"
}

locals {
  globals = yamldecode(file("../../../globals.yaml"))
  name            = "lapalma"
  environment     = "prod"
}
include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path                             = "../network"
  mock_outputs_merge_with_state           = true
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    "vpc_id" = "id-dummy"
  }
}

inputs = {
  vpc_id     = dependency.vpc.outputs.vpc_id
  node_count = 2
  project    = {
    name        = local.name
    environment = local.environment
  }
}