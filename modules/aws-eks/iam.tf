# ------------------------------------------------------------
# IAM Role — Control Plane
# Permite que o EKS gira recursos AWS em teu nome
# ------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  name = "satubinha-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "satubinha-${var.environment}-eks-cluster-role"
    Environment = var.environment
  }
}

# Política gerida pela AWS — permissões mínimas para o control plane
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ------------------------------------------------------------
# IAM Role — Nodes
# Permite que os nodes se registem no cluster e acedam ao ECR
# ------------------------------------------------------------
resource "aws_iam_role" "nodes" {
  name = "satubinha-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "satubinha-${var.environment}-eks-node-role"
    Environment = var.environment
  }
}

# Três políticas obrigatórias para os nodes
resource "aws_iam_role_policy_attachment" "nodes_worker_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "nodes_cni_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "nodes_ecr_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}