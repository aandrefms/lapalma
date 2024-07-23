terraform {
  source ="../../modules/messaging"
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
}