data "aws_region" "current" {}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}