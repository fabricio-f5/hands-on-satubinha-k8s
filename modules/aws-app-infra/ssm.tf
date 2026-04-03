# ------------------------------------------------------------
# SSM Parameters — secrets da aplicação
# Acedidos pelos pods via IRSA sem credenciais estáticas
# ------------------------------------------------------------
resource "aws_ssm_parameter" "db_password" {
  name        = "/satubinha/${var.environment}/db_password"
  description = "Password do PostgreSQL"
  type        = "SecureString"
  value       = var.db_password

  tags = {
    Name        = "satubinha-${var.environment}-db-password"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_user" {
  name        = "/satubinha/${var.environment}/db_user"
  description = "Utilizador do PostgreSQL"
  type        = "SecureString"
  value       = var.db_user

  tags = {
    Name        = "satubinha-${var.environment}-db-user"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/satubinha/${var.environment}/db_name"
  description = "Nome da base de dados"
  type        = "String"
  value       = var.db_name

  tags = {
    Name        = "satubinha-${var.environment}-db-name"
    Environment = var.environment
  }
}