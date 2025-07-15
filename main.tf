provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # Enable NAT Gateway (one per AZ for high availability)
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # Enable DNS support and hostnames
  enable_dns_support   = true
  enable_dns_hostnames = true

  # VPC Flow Logs to CloudWatch
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  # Subnet tagging for EKS
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = merge(
    var.tags,
    {
      "Terraform"   = "true"
      "Environment" = "production"
    }
  )
}

# Additional security group for EKS worker nodes
resource "aws_security_group" "eks_worker_sg" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name"                                      = "${var.cluster_name}-worker-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

resource "aws_security_group_rule" "worker_ingress_self" {
  description              = "Allow worker nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_worker_sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  to_port                  = 65535
  type                     = "ingress"
}

# Security group for EKS cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-cluster-sg"
    }
  )
}

resource "aws_security_group_rule" "cluster_ingress_worker_https" {
  description              = "Allow pods to communicate with the EKS cluster API"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_worker_sg.id
  to_port                  = 443
  type                     = "ingress"
}

# VPC Endpoints for EKS
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-s3-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets

  security_group_ids = [
    aws_security_group.eks_worker_sg.id,
  ]

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-ecr-api-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets

  security_group_ids = [
    aws_security_group.eks_worker_sg.id,
  ]

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-ecr-dkr-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets

  security_group_ids = [
    aws_security_group.eks_worker_sg.id,
  ]

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-logs-endpoint"
    }
  )
}