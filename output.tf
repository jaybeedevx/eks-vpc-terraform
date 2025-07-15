output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "eks_worker_sg_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks_worker_sg.id
}

output "eks_cluster_sg_id" {
  description = "Security group ID for EKS cluster"
  value       = aws_security_group.eks_cluster_sg.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}