resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "server-host-key"
  public_key = tls_private_key.key.public_key_openssh
}

resource "aws_ssm_parameter" "bastion_host_private_key" {
  name  = "/LAPALMA/US_EAST_1/SERVER_HOST/PRIVATE_KEY"
  type  = "SecureString"
  value = tls_private_key.key.private_key_pem
}

resource "aws_ssm_parameter" "bastion_host_public_key" {
  name  = "/LAPALMA/US_EAST_1/SERVER_HOST/PUBLIC_KEY"
  type  = "SecureString"
  value = tls_private_key.key.public_key_openssh
}

