# ------------------------------------------------------------
# root.hcl — configuração comum a todas as layers
# Backend S3, provider AWS e tags globais
# Padrão DRY — cada layer herda via include "root"
# ------------------------------------------------------------

locals {
  environment = basename(dirname(get_terragrunt_dir()))
}

# ------------------------------------------------------------
# Backend S3 — state isolado por ambiente e layer
# ------------------------------------------------------------
remote_state {
  backend = "s3"
  
  config = {
    bucket         = "hands-on-satubinha-k8s-tfstate"
    key            = "environments/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# ------------------------------------------------------------
# Provider AWS — gerado automaticamente em cada layer
# ------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "hands-on-satubinha-k8s"
      Environment = "${local.environment}"
      ManagedBy   = "terragrunt"
      Repository  = "hands-on-satubinha-k8s"
    }
  }
}

provider "tls" {}
EOF
}

