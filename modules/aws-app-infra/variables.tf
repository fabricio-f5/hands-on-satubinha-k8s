variable "environment" {
  description = "Nome do ambiente (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint do cluster EKS — output da layer eks"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Certificado CA do cluster — output da layer eks"
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