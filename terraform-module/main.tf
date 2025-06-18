# --------------------------------------------------------------
# calling Public EC2 instance Module to create a public instance
# --------------------------------------------------------------

module "my_ec2" {
  source        = "./modules/ec2"
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  name          = var.name
}