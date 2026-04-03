include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws-app-infra"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id = "vpc-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name           = "satubinha-dev-mock"
    cluster_endpoint       = "https://mock.eks.amazonaws.com"
    cluster_ca_certificate = "mock-ca-certificate"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment = "dev"

  # --- EKS — vem da layer eks ---
  cluster_name           = dependency.eks.outputs.cluster_name
  cluster_endpoint       = dependency.eks.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.eks.outputs.cluster_ca_certificate

  # --- Secrets --- 
  db_name     = "satubinha"
  db_user     = get_env("TF_VAR_db_user")
  db_password = get_env("TF_VAR_db_password")
}