variable "environment" {
  description = "Nome do ambiente (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes"
  type        = string
}

# --- Rede ---
variable "vpc_id" {
  description = "ID da VPC — output da layer network"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas — onde os nodes correm"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs das subnets públicas — onde o ALB fica"
  type        = list(string)
}

# --- Node Group ---
variable "instance_type" {
  description = "Tipo de instância EC2 para os nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired" {
  description = "Número desejado de nodes"
  type        = number
  default     = 2
}

variable "node_min" {
  description = "Número mínimo de nodes"
  type        = number
  default     = 1
}

variable "node_max" {
  description = "Número máximo de nodes"
  type        = number
  default     = 3
}