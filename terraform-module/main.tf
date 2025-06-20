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

  tags = merge(
    local.common_tags,
    {
      Name = "Quiva_Bastion_key"
    }
  )
}

# --------------------------------------------------------------
# calling Public EC2 instance Module to create a public instance
# --------------------------------------------------------------

module "my_ec2" {
  source        = "./modules/ec2"
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  name          = "Quiva_bastion_server"
  key_name      = aws_key_pair.Quiva_bastion_key.key_name

  tags = merge(
    local.common_tags,
    {
      Name = "Quiva_public_server"
    }
  )
}

# ==================== VPC Creation ==================== #
module "Quiva_Vpc" {
  source     = "./modules/vpc"
  cidr_block = var.vpc_cidr_block
  vpc_name   = "Quiva_Vpc"
  tags = merge(
    local.common_tags,
    {
      Name = "Quiva_vpc"
    }
  )
}