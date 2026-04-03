output "app_role_arn" {
  description = "ARN da IAM Role dos pods — usado na annotation do ServiceAccount K8s"
  value       = aws_iam_role.app.arn
}

output "oidc_provider_arn" {
  description = "ARN do OIDC Provider — referência para debugging e outros módulos"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "ssm_db_password_path" {
  description = "Path SSM da password do DB — referenciado nos manifests K8s"
  value       = aws_ssm_parameter.db_password.name
}

output "ssm_db_user_path" {
  description = "Path SSM do utilizador do DB — referenciado nos manifests K8s"
  value       = aws_ssm_parameter.db_user.name
}

output "ssm_db_name_path" {
  description = "Path SSM do nome do DB — referenciado nos manifests K8s"
  value       = aws_ssm_parameter.db_name.name
}