variable "environment" {
  description = "Nome do ambiente (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS — usado nas tags obrigatórias para o ALB controller"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para as subnets públicas (uma por AZ)"
  type        = list(string)
  ephemeral   = true
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para as subnets privadas (uma por AZ)"
  type        = list(string)
  ephemeral   = true
}

variable "availability_zones" {
  description = "Lista de AZs onde as subnets serão criadas"
  type        = list(string)
  ephemeral   = true
}