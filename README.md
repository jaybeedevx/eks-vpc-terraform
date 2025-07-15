# AWS VPC for EKS Cluster - Terraform Module

This Terraform module creates a production-grade VPC for Amazon EKS clusters with proper networking, security, and high availability configurations.

## Features

- Multi-AZ deployment for high availability
- Public and private subnets with proper routing
- NAT gateways for outbound internet access from private subnets
- VPC endpoints for AWS services (ECR, S3, CloudWatch Logs)
- Proper security groups for EKS cluster and worker nodes
- VPC Flow Logs enabled for monitoring

## Usage

```hcl
module "eks_vpc" {
  source = "github.com/your-org/eks-vpc-terraform"

  cluster_name          = "production-eks"
  region               = "us-west-2"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Environment = "production"
    Team        = "DevOps"
  }
}