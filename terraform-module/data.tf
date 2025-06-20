# --------------------------------------------------------------
# Get IP address automatically
# --------------------------------------------------------------
# data "http" "sys_ip" {
#   url = "https://ipv4.icanhazip.com"
# }

# # --------------------------------------------------------------
# # Fetch Amazon AMI automatically
# # --------------------------------------------------------------

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