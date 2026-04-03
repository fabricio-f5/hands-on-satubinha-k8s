variable "environment" {
  description = "Nome do ambiente (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN do OIDC Provider — output da layer eks"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL do OIDC Provider — output da layer eks"
  type        = string
}

variable "db_password" {
  description = "Password do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "db_user" {
  description = "Utilizador do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nome da base de dados"
  type        = string
}