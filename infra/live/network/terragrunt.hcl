terraform {
  source ="../../modules/network/"
}

locals {
  globals = yamldecode(file("../../../globals.yaml"))
  name            = "lapalma"
  environment     = "prod"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  project = {
    name        = local.name
    environment = local.environment
  }
}
