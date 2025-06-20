# --------------------------------------------------------------
# Public EC2 instance creation
# --------------------------------------------------------------

resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  associate_public_ip_address = true
  key_name = var.key_name

  tags = merge(
    var.tags,
    {
         Name = var.name,
    }
  )
}