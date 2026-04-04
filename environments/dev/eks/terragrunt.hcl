include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws-eks"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id             = "vpc-mock"
    public_subnet_ids  = ["subnet-mock-public-1", "subnet-mock-public-2"]
    private_subnet_ids = ["subnet-mock-private-1", "subnet-mock-private-2"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment     = "dev"
  cluster_name    = "satubinha-dev"
  cluster_version = "1.32"

  # --- Rede — vem da layer network ---
  vpc_id             = dependency.network.outputs.vpc_id
  public_subnet_ids  = dependency.network.outputs.public_subnet_ids
  private_subnet_ids = dependency.network.outputs.private_subnet_ids

  # --- Node Group ---
  instance_type = "t3.small"
  node_desired  = 2
  node_min      = 1
  node_max      = 3
}