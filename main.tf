###########################################################
# PROVIDER
###########################################################
provider "aws" {
  region = var.aws_region
}

###########################################################
# VPC MODULE (2 Subnets Required for ALB)
###########################################################
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_a_cidr = "10.0.1.0/24"
  public_subnet_b_cidr = "10.0.2.0/24"

  az1 = "ap-south-1a"
  az2 = "ap-south-1b"

  env = terraform.workspace
}

###########################################################
# SECURITY GROUP FOR EC2
###########################################################
resource "aws_security_group" "web_sg" {
  name        = "${terraform.workspace}-web-sg"
  description = "Allow HTTP + SSH"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-web-sg"
  }
}

###########################################################
# SECURITY GROUP FOR ALB
###########################################################
resource "aws_security_group" "alb_sg" {
  name        = "${terraform.workspace}-alb-sg"
  description = "Allow HTTP to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-alb-sg"
  }
}

###########################################################
# EC2 MODULE (use subnet A)
###########################################################
module "ec2" {
  source        = "./modules/ec2"
  instance_type = var.instance_type
  subnet_id     = module.vpc.subnet_a_id
  key_name      = var.key_name
  env           = terraform.workspace
}

###########################################################
# AUTOSCALING MODULE
###########################################################
module "autoscaling" {
  source            = "./modules/autoscaling"
  ami_id            = data.aws_ami.amazon_linux.id
  instance_type     = var.instance_type
  vpc_id            = module.vpc.vpc_id

  subnet_a_id       = module.vpc.subnet_a_id
  subnet_b_id       = module.vpc.subnet_b_id

  key_name          = var.key_name
  security_group_id = aws_security_group.web_sg.id
  alb_security_group_id = aws_security_group.alb_sg.id

  env               = terraform.workspace
  min_size          = var.asg_min
  max_size          = var.asg_max
  desired_capacity  = var.asg_desired
}

###########################################################
# AMI
###########################################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

###########################################################
# OUTPUTS
###########################################################
output "instance_id" {
  value = module.ec2.instance_id
}

output "autoscaling_lb_dns" {
  value = module.autoscaling.load_balancer_dns
}
