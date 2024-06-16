# File: main.tf

provider "aws" {
  region = "us-east-1" # Specify your preferred region
}

# Data source to check if a VPC with a specific name tag already exists
data "aws_vpcs" "existing" {
  filter {
    name   = "tag:Name"
    values = ["MyVPC"]  # Replace with the desired VPC name tag
  }
}

# Resource block to create a new VPC only if it does not exist
resource "aws_vpc" "my_vpc" {
  count                = length(data.aws_vpcs.existing.ids) == 0 ? 1 : 0
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"  # This is the tag name to identify the VPC
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Outputs to display the details of the VPC
output "vpc_id" {
  value = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.ids[0] : aws_vpc.my_vpc[0].id
}

output "vpc_cidr_block" {
  value = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.cidr_blocks[0] : aws_vpc.my_vpc[0].cidr_block
}
