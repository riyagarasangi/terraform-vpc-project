# AWS Region
variable "aws_region" {
  default = "ap-south-1"
}

# VPC and Networking
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  default = "ap-south-1a"
}

# EC2 Instance Type (FREE-TIER ELIGIBLE)
# NOTE: t3.micro is the recommended free-tier type for new accounts
variable "instance_type" {
  default = "t3.micro"
}

# Key Pair Name for EC2/ASG
variable "key_name" {}

# Autoscaling Configuration
variable "asg_min" {
  default = 1
}

variable "asg_max" {
  default = 3
}

variable "asg_desired" {
  default = 2
}
