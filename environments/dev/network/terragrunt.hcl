include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws-eks-network"
}

inputs = {
  environment  = "dev"
  cluster_name = "satubinha-dev"

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnet_cidrs = [
    "10.0.1.0/24",  # us-east-1a
    "10.0.2.0/24"   # us-east-1b
  ]

  private_subnet_cidrs = [
    "10.0.10.0/24", # us-east-1a
    "10.0.11.0/24"  # us-east-1b
  ]
}