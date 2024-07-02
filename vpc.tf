provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "example-vpc"
  }
}

resource "null_resource" "enable_public_ip" {
  count = length(module.vpc.public_subnets)

  provisioner "local-exec" {
    command = "aws ec2 modify-subnet-attribute --subnet-id ${element(module.vpc.public_subnets, count.index)} --map-public-ip-on-launch"
  }
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "The public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "The private subnets"
  value       = module.vpc.private_subnets
}
