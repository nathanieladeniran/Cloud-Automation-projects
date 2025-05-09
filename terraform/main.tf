
# --------------------------------------------------------------
# Get IP address automatically
# --------------------------------------------------------------


data "http" "sys_ip" {
  url = "https://ipv4.icanhazip.com"
}

# --------------------------------------------------------------
# VPC creation
# --------------------------------------------------------------

resource "aws_vpc" "Nath-VPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Nath_vpc"
  }
}

# --------------------------------------------------------------
# Subnet creation
# --------------------------------------------------------------

resource "aws_subnet" "Nath_public_subnet" {
  vpc_id            = aws_vpc.Nath-VPC.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Nath_public_subnet_1a"
  }
}

# --------------------------------------------------------------
# Internet Gateway creation
# --------------------------------------------------------------

resource "aws_internet_gateway" "Nath_igw" {
  vpc_id = aws_vpc.Nath-VPC.id
  tags = {
    Name = "Nath_igw"
  }
}

# --------------------------------------------------------------
# Security Group creation
# --------------------------------------------------------------

resource "aws_security_group" "Nath_Bastion_sg" {
  vpc_id      = aws_vpc.Nath-VPC.id
  name        = "Allow SSH"
  description = "Allow traffic from ssg"

  tags = {
    Name = "Nath_sg"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["${chomp(data.http.sys_ip.response_body)}/32"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}