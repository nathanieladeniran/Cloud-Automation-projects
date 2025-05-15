
# --------------------------------------------------------------
# Get IP address automatically
# --------------------------------------------------------------
data "http" "sys_ip" {
  url = "https://ipv4.icanhazip.com"
}

# --------------------------------------------------------------
# Fetch Amazon AMI automatically
# --------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"] # Amazon's official AMIs
}

# --------------------------------------------------------------
# Fetch Ubuntu AMI automatically
# --------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical (official Ubuntu AMIs)
}

# --------------------------------------------------------------
# VPC creation
# --------------------------------------------------------------

resource "aws_vpc" "Nath-VPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true #DNS name won’t show unless DNS hostnames are enabled on your VPC with this line
  tags = {
    Name = "Nath_vpc"
  }
}

# --------------------------------------------------------------
# Public Subnet for Bastion Server / Jump Host creation
# --------------------------------------------------------------

resource "aws_subnet" "Nath_public_subnet" {
  vpc_id                  = aws_vpc.Nath-VPC.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true #Only used when the subnet is for the public
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
# Route Table creation
# --------------------------------------------------------------

resource "aws_route_table" "Nath_route_table" {
  vpc_id = aws_vpc.Nath-VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Nath_igw.id
  }
}

# --------------------------------------------------------------
# Route Table Association
# --------------------------------------------------------------

resource "aws_route_table_association" "Nath_table_assoc" {
  route_table_id = aws_route_table.Nath_route_table.id
  subnet_id      = aws_subnet.Nath_public_subnet.id
}

# --------------------------------------------------------------
# Key pair creation
# --------------------------------------------------------------

# SSH Key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "Nath_key" {
  key_name   = "Nath-Key"
  public_key = file("${path.module}/Nath-Key.pub") #file("~/.ssh/Nath-Key.pub")  # first generate the public key (ssh-keygen -t rsa -b 4096 -f ~/.ssh/Nath-Key) then access it with this line
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
    to_port   = 22
    protocol  = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["${chomp(data.http.sys_ip.response_body)}/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# --------------------------------------------------------------
# Public EC2 instance creation
# --------------------------------------------------------------

resource "aws_instance" "Nath_Bastion_server" {
  ami                         = data.aws_ami.amazon_linux.id
  vpc_security_group_ids      = [aws_security_group.Nath_Bastion_sg.id]
  subnet_id                   = aws_subnet.Nath_public_subnet.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.Nath_key.key_name
  # key_name = "S-key"  #use this if the key has been created before and its available on the aws console 
  tags = {
    Name = "Nath_server"
  }
}

# Private Server Section #

# --------------------------------------------------------------
# Private Subnet creation
# --------------------------------------------------------------
resource "aws_subnet" "Nath_private_subnet" {
  vpc_id            = aws_vpc.Nath-VPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Nath_private_subnet_1a"
  }
}

# --------------------------------------------------------------
# NAT Gateway creation
# --------------------------------------------------------------
resource "aws_eip" "Nath_nat_eip" {
  tags = {
    Name = "Nath_Nat_EIP"
  }
}

resource "aws_nat_gateway" "Nath_nat_gateway" {
  allocation_id = aws_eip.Nath_nat_eip.id
  subnet_id     = aws_subnet.Nath_private_subnet.id
}

# --------------------------------------------------------------
# Private Route Table
# --------------------------------------------------------------

resource "aws_route_table" "Nath_private_route_table" {
  vpc_id = aws_vpc.Nath-VPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Nath_nat_gateway.id
  }

}

# --------------------------------------------------------------
# Private Security Group
# --------------------------------------------------------------
resource "aws_security_group" "Nath_private_sg" {
  vpc_id      = aws_vpc.Nath-VPC.id
  description = "Allow SSH from Bastion host alone"
  name        = "Nath Private SG"
  tags = {
    Name = "Nath_private_sg"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.Nath_Bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# --------------------------------------------------------------
# Private EC2 instance/server
# --------------------------------------------------------------

resource "aws_instance" "Nath_private_server" {
  ami                         = data.aws_ami.amazon_linux.id
  vpc_security_group_ids      = [aws_security_group.Nath_private_sg.id]
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.Nath_private_subnet.id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.Nath_key.key_name

  tags = {
    Name = "Nath_private_server"
  }

}