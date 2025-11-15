resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  tags = { Name = "${var.env}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "${var.env}-igw" }
}

# Subnet 1
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-public-subnet-a"
  }
}

# Subnet 2
resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = var.az2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-public-subnet-b"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

output "subnet_a_id" { value = aws_subnet.public_subnet_a.id }
output "subnet_b_id" { value = aws_subnet.public_subnet_b.id }
output "vpc_id"      { value = aws_vpc.main_vpc.id }
