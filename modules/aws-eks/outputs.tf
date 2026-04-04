output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint do API server do cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Certificado CA do cluster — necessário para autenticação kubectl"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_group_role_arn" {
  description = "ARN da IAM Role dos nodes — usado pela layer app-infra para IRSA"
  value       = aws_iam_role.nodes.arn
}

output "oidc_provider_arn" {
  description = "ARN do OIDC Provider — passado para o aws-app-infra"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "URL do OIDC Provider — passado para o aws-app-infra"
  value       = aws_iam_openid_connect_provider.this.url
}

output "alb_controller_role_arn" {
  description = "ARN da IAM Role do ALB Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN da IAM Role do EBS CSI Driver"
  value       = aws_iam_role.ebs_csi_driver.arn
}