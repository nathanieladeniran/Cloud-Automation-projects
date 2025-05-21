
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

resource "aws_vpc" "Quiva-VPC" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true #DNS name won’t show unless DNS hostnames are enabled on your VPC with this line
  tags = {
    Name        = "Quiva_vpc"
    Purpose     = element(var.Purpose, 1)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}

# --------------------------------------------------------------
# Key pair creation and storing
# --------------------------------------------------------------

# creating the key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# This creates a private key file and upload to AWS
resource "local_file" "Quiva_private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/Quiva-Key-Pair.pem"
  file_permission = "0400"
}
resource "aws_key_pair" "Quiva_bastion_key" {
  key_name   = "Quiva-Key-Pair"
  public_key = tls_private_key.ssh_key.public_key_openssh
  # public_key = file("${path.module}/Quiva-Key.pub") #file("~/.ssh/Quiva-Key.pub")  # first generate the public key (ssh-keygen -t rsa -b 4096 -f ~/.ssh/Quiva-Key) then access it with this line
}


# --------------------------------------------------------------
# Public Subnet for Bastion Server / Jump Host creation
# --------------------------------------------------------------

resource "aws_subnet" "Quiva_public_subnet" {
  vpc_id                  = aws_vpc.Quiva-VPC.id
  count                   = length(var.availability_zone)
  cidr_block              = cidrsubnet(aws_vpc.Quiva-VPC.cidr_block, 8, count.index)
  availability_zone       = element(var.availability_zone, count.index)
  map_public_ip_on_launch = true #Only used when the subnet is for the public
  tags = {
    Name        = "Quiva_public_subnet_${substr(element(var.availability_zone, count.index), -2, 2)}"
    Purpose     = element(var.Purpose, 1)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}

# --------------------------------------------------------------
# Internet Gateway creation
# --------------------------------------------------------------

resource "aws_internet_gateway" "Quiva_igw" {
  vpc_id = aws_vpc.Quiva-VPC.id
  tags = {
    Name        = "Quiva_igw"
    Purpose     = element(var.Purpose, 1)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}

# --------------------------------------------------------------
# Public Route Table creation
# --------------------------------------------------------------

resource "aws_route_table" "Quiva_public_route_table" {
  vpc_id = aws_vpc.Quiva-VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Quiva_igw.id
  }
  tags = {
    Name        = "Quiva_pubic_rt"
    Purpose     = element(var.Purpose, 1)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }

}

# --------------------------------------------------------------
# Public Route Table Association
# --------------------------------------------------------------

resource "aws_route_table_association" "public_internet_server" {
  count          = length(aws_subnet.Quiva_public_subnet)
  route_table_id = aws_route_table.Quiva_public_route_table.id
  subnet_id      = element(aws_subnet.Quiva_public_subnet.*.id, count.index)
}

# --------------------------------------------------------------
# Security Group creation
# --------------------------------------------------------------

resource "aws_security_group" "Quiva_Bastion_sg" {
  vpc_id      = aws_vpc.Quiva-VPC.id
  name        = "Quiva Public SG"
  description = "Allow traffic from ssg"

  tags = {
    Name        = "Quiva_public_sg"
    Purpose     = element(var.Purpose, 1)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
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
# Bastion EIP creation
# --------------------------------------------------------------
resource "aws_eip" "Quiva_bastion_eip" {

  depends_on = [
    aws_internet_gateway.Quiva_igw
  ]
  tags = {
    Name        = "Quiva_Bastion_EIP"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}

# --------------------------------------------------------------
# Associate the EIP with the Bastion EC2 instance
# --------------------------------------------------------------

resource "aws_eip_association" "Quiva_bastion_eip_assoc" {
  instance_id   = aws_instance.Quiva_Bastion_server.id
  allocation_id = aws_eip.Quiva_bastion_eip.id
}

# --------------------------------------------------------------
# Public EC2 instance creation
# --------------------------------------------------------------

resource "aws_instance" "Quiva_Bastion_server" {
  ami                         = data.aws_ami.amazon_linux.id
  vpc_security_group_ids      = [aws_security_group.Quiva_Bastion_sg.id]
  subnet_id                   = aws_subnet.Quiva_public_subnet[0].id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.Quiva_bastion_key.key_name
  # key_name = "S-key"  #use this if the key has been created before and its available on the aws console 

  tags = {
    Name        = "Quiva_public_server"
    Purpose     = element(var.Purpose, 1)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}

#                        
# Private Server Section #
# 

# --------------------------------------------------------------
# Private Subnet creation
# --------------------------------------------------------------
resource "aws_subnet" "Quiva_private_subnet" {
  vpc_id                  = aws_vpc.Quiva-VPC.id
  count                   = length(var.availability_zone)
  cidr_block              = cidrsubnet(aws_vpc.Quiva-VPC.cidr_block, 8, count.index + 10)
  availability_zone       = element(var.availability_zone, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name        = "Quiva_private_subnet_${substr(element(var.availability_zone, count.index), -2, 2)}"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}

# --------------------------------------------------------------
# ELastic IP creation
# --------------------------------------------------------------
resource "aws_eip" "Quiva_nat_eip" {
  depends_on = [
    aws_internet_gateway.Quiva_igw
  ]
  tags = {
    Name        = "Quiva_Nat_EIP"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}

# --------------------------------------------------------------
# NAT Gateway creation
# --------------------------------------------------------------
resource "aws_nat_gateway" "Quiva_nat_gateway" {
  allocation_id = aws_eip.Quiva_nat_eip.id
  subnet_id     = aws_subnet.Quiva_public_subnet[0].id # element(aws_subnet.Quiva_public_subnet.*.id, 0)
  depends_on = [
    aws_internet_gateway.Quiva_igw
  ]

  tags = {
    Name        = "Quiva_Nat_Gateway"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }

}

# --------------------------------------------------------------
# Private Route Table
# --------------------------------------------------------------

resource "aws_route_table" "Quiva_private_route_table" {
  vpc_id = aws_vpc.Quiva-VPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Quiva_nat_gateway.id
  }

  tags = {
    Name        = "Quiva_private_rt"
    Purpose     = element(var.Purpose, 1)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }

}

# --------------------------------------------------------------
# Private Route Table Association
# --------------------------------------------------------------

resource "aws_route_table_association" "private_internet_server" {
  count          = length(aws_subnet.Quiva_private_subnet)
  route_table_id = aws_route_table.Quiva_private_route_table.id
  subnet_id      = element(aws_subnet.Quiva_private_subnet.*.id, count.index)
}

# --------------------------------------------------------------
# Private Security Group
# --------------------------------------------------------------
resource "aws_security_group" "Quiva_private_sg" {
  vpc_id      = aws_vpc.Quiva-VPC.id
  description = "Allow SSH from Bastion host alone"
  name        = "Quiva Private SG"
  tags = {
    Name        = "Quiva_private_sg"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.Quiva_Bastion_sg.id]
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

resource "aws_instance" "Quiva_private_server" {
  ami                         = data.aws_ami.amazon_linux.id
  vpc_security_group_ids      = [aws_security_group.Quiva_private_sg.id]
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.Quiva_private_subnet[0].id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.Quiva_bastion_key.key_name
  private_ip                  = cidrhost(aws_subnet.Quiva_private_subnet[0].cidr_block, var.private_server_ip_index)

  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Install Docker
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user

              # Install Nginx
              amazon-linux-extras enable nginx1 -y
              yum install nginx -y
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name        = "Quiva_private_server"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }

}

#                        
# RDS Private Section #
#

# --------------------------------------------------------------
# Private RDS subnet
# --------------------------------------------------------------

resource "aws_subnet" "private_rds_subnet" {
  vpc_id            = aws_vpc.Quiva-VPC.id
  count             = length(var.availability_zone)
  cidr_block        = cidrsubnet(aws_vpc.Quiva-VPC.cidr_block, 8, count.index + 20)
  availability_zone = element(var.availability_zone, count.index)

  tags = {
    Name        = "Quiva_private_rds_subnet_${substr(element(var.availability_zone, count.index), -2, 2)}"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }

}

# --------------------------------------------------------------
# Private subnet groups
# --------------------------------------------------------------

resource "aws_db_subnet_group" "private_rdsmain_subnet_group" {
  name        = "rds_subnet_group"
  description = "Private subnets for RDS instance"
  subnet_ids  = aws_subnet.private_rds_subnet[*].id

  tags = {
    Name        = "RDS_Subnet_Group"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}

# --------------------------------------------------------------
# Private RDS security groups
# --------------------------------------------------------------
resource "aws_security_group" "private_rds_sg" {
  vpc_id      = aws_vpc.Quiva-VPC.id
  name        = "private_rds_sg"
  description = "Allow MySQL access from private subnet"

  tags = {
    Name        = "Quiva_rds_sg"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.Quiva_private_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"

  }

}

# --------------------------------------------------------------
# Private RDS Instance
# --------------------------------------------------------------
resource "aws_db_instance" "private_db_instance" {
  allocated_storage      = 10
  identifier             = "private-rds-instance"
  db_name                = "max_db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "Ibiyosi#141"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.private_rdsmain_subnet_group.name
  vpc_security_group_ids = [aws_security_group.private_rds_sg.id]
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  copy_tags_to_snapshot   = true
  multi_az                = true

  tags = {
    Name        = "Quiva_rds"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}

# --------------------------------------------------------------
# Create s3 bucket
# --------------------------------------------------------------

resource "random_id" "identify_number" {
  byte_length = 4
}

resource "aws_s3_bucket" "store_bucket" {
  bucket = "buck-${random_id.identify_number.hex}"
  tags = {
    Name = "App-bucket-${random_id.identify_number.hex}"
    Purpose     = element(var.Purpose, 0)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }
}