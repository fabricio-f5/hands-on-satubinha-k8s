include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws-app-infra"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name        = "satubinha-dev-mock"
    oidc_provider_arn   = "arn:aws:iam::123456789:oidc-provider/mock"
    oidc_provider_url   = "https://oidc.eks.us-east-1.amazonaws.com/id/mock"
    alb_controller_role_arn = "arn:aws:iam::123456789:role/mock-alb-role"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment       = "dev"
  cluster_name      = dependency.eks.outputs.cluster_name
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url = dependency.eks.outputs.oidc_provider_url

  db_name     = "satubinha"
  db_user     = get_env("TF_VAR_db_user")
  db_password = get_env("TF_VAR_db_password")
}