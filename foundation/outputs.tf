output "github_actions_role_arn" {
  description = "ARN da IAM Role para o GitHub Actions do satubinha-k8s"
  value       = aws_iam_role.github_actions.arn
}