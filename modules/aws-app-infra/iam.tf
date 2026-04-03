# ------------------------------------------------------------
# IAM Role para os pods da aplicação (IRSA)
# O OIDC Provider está agora no módulo aws-eks
# ------------------------------------------------------------
resource "aws_iam_role" "app" {
  name = "satubinha-${var.environment}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:default:satubinha-app"
          "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "satubinha-${var.environment}-app-role"
    Environment = var.environment
  }
}

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

data "aws_caller_identity" "current" {}