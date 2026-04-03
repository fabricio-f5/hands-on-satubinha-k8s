# ------------------------------------------------------------
# Security Group — Control Plane
# Controla o tráfego entre o control plane e os nodes
# ------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name        = "satubinha-${var.environment}-eks-cluster-sg"
  description = "Security group do control plane EKS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "satubinha-${var.environment}-eks-cluster-sg"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# Cluster EKS — Control Plane
# ------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# Node Group — EC2s que correm os pods
# ------------------------------------------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "satubinha-${var.environment}-nodes"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.node_desired
    min_size     = var.node_min
    max_size     = var.node_max
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_worker_policy,
    aws_iam_role_policy_attachment.nodes_cni_policy,
    aws_iam_role_policy_attachment.nodes_ecr_policy,
  ]

  tags = {
    Name        = "satubinha-${var.environment}-nodes"
    Environment = var.environment
  }
}