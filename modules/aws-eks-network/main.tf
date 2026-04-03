# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "satubinha-${var.environment}-vpc"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# Subnets públicas — uma por AZ
# Usadas pelo ALB (Load Balancer externo)
# ------------------------------------------------------------
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name                                        = "satubinha-${var.environment}-public-${var.availability_zones[count.index]}"
    Environment                                 = var.environment
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ------------------------------------------------------------
# Subnets privadas — uma por AZ
# Usadas pelos nodes do EKS
# ------------------------------------------------------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                        = "satubinha-${var.environment}-private-${var.availability_zones[count.index]}"
    Environment                                 = var.environment
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ------------------------------------------------------------
# Internet Gateway
# ------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "satubinha-${var.environment}-igw"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# Elastic IP para o NAT Gateway
# ------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "satubinha-${var.environment}-nat-eip"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# NAT Gateway — dev: 1 apenas para reduzir custo
# ------------------------------------------------------------
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "satubinha-${var.environment}-nat"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------
# Route table pública → IGW
# ------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "satubinha-${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------
# Route table privada → NAT Gateway
# ------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name        = "satubinha-${var.environment}-private-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}