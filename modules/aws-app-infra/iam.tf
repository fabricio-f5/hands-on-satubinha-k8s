# ------------------------------------------------------------
# OIDC Provider — regista o cluster EKS como identity provider
# Permite que pods assumam IAM Roles via ServiceAccount
# ------------------------------------------------------------
data "tls_certificate" "cluster" {
  url = var.cluster_endpoint
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = var.cluster_endpoint

  tags = {
    Name        = "satubinha-${var.environment}-oidc"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# IAM Role para os pods da aplicação (IRSA)
# Permite acesso ao ECR e SSM sem credenciais estáticas
# ------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "app" {
  name = "satubinha-${var.environment}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.this.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:sub" = "system:serviceaccount:default:satubinha-app"
          "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "satubinha-${var.environment}-app-role"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# Política — ECR pull
# ------------------------------------------------------------
resource "aws_iam_role_policy" "ecr" {
  name = "ecr-pull"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken"
      ]
      Resource = "*"
    }]
  })
}

# ------------------------------------------------------------
# Política — SSM read
# ------------------------------------------------------------
resource "aws_iam_role_policy" "ssm" {
  name = "ssm-read"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      Resource = "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/satubinha/${var.environment}/*"
    }]
  })
}