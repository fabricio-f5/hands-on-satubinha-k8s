provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------
# Reutiliza o OIDC Provider existente via data source
# Não cria um novo — só pode existir um por conta AWS
# ------------------------------------------------------------
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ------------------------------------------------------------
# IAM Role dedicada ao hands-on-satubinha-k8s
# ------------------------------------------------------------
resource "aws_iam_role" "github_actions" {
  name = "github-actions-satubinha-k8s"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })

  tags = {
    Name    = "github-actions-satubinha-k8s"
    Project = "hands-on-satubinha-k8s"
  }
}

# ------------------------------------------------------------
# Policy — permissões necessárias para o pipeline
# ------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-satubinha-k8s-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKS"
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2VPC"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAM"
        Effect = "Allow"
        Action = [
          "iam:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSM"
        Effect = "Allow"
        Action = [
          "ssm:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECR"
        Effect = "Allow"
        Action = [
          "ecr:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3State"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetBucketLogging",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:CreateBucket",
          "s3:PutBucketVersioning",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketPolicy"          
        ]
        Resource = [
        "arn:aws:s3:::hands-on-satubinha-tfstate",
        "arn:aws:s3:::hands-on-satubinha-tfstate/*",
        "arn:aws:s3:::hands-on-satubinha-k8s-tfstate",
        "arn:aws:s3:::hands-on-satubinha-k8s-tfstate/*"
        ]
      },
      {
        Sid    = "ELB"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      }
    ]
  })
}