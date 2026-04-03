output "vpc_id" {
  description = "ID da VPC — usado pela layer eks"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas — usadas pelo ALB"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas — usadas pelos nodes EKS"
  value       = aws_subnet.private[*].id
}