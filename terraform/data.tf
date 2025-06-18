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
# Calling dynamo table created ealier with aws cli
# --------------------------------------------------------------
data "aws_dynamodb_table" "Quiva_terrform_locks" {
  name = "Quiva-tfstate-lock"
}

# --------------------------------------------------------------
# User data for ec2 template file
# --------------------------------------------------------------
data "template_file" "apache_user_data" {
  template = file("${path.module}/apache_user_data.tpl")

  vars = {
    db_host = aws_db_instance.private_db_instance.endpoint
  }

}