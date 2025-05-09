
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
# Fetch Amazon AMI automatically
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

# --------------------------------------------------------------
# EC2 instance creation
# --------------------------------------------------------------

resource "aws_instance" "Nath_server" {
    ami = data.aws_ami.amazon_linux.id
    vpc_security_group_ids = [aws_security_group.Nath_Bastion_sg.id]
    subnet_id = aws_subnet.Nath_public_subnet.id
    instance_type = "t2.micro"
    
    tags = {
      Name = "Nath_server"
    }
}