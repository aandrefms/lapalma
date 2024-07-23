locals {
  project_name        = "${var.project.name}-${var.project.environment}"
  ubuntu_22_04_ami_id = "ami-0a0e5d9c7acc336f1"
  environment         = var.project.environment
}
