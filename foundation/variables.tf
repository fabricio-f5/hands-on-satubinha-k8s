variable "github_repo" {
  description = "Repositório GitHub autorizado a assumir a role"
  type        = string
  default     = "fabricio-f5/hands-on-satubinha-k8s"
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}