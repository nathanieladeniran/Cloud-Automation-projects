#                                                         #
# ================= Networking Section ================== #
#                                                         #

# Public Subnets for public EC2 #
resource "aws_subnet" "Quiva_public_subnet" {
  vpc_id = module.Quiva_Vpc.vpc_id
  count = length(var.availability_zone)
  cidr_block = cidrsubnet(module.Quiva_Vpc.vpc_cidr_block, 8, count.index)
  availability_zone = element(var.availability_zone, count.index)
  map_public_ip_on_launch = true #Only used when the subnet is for the public

  tags = merge(
    local.common_tags,
    {
      Name = "Quiva_public_subnet_${substr(element(var.availability_zone, count.index), -2, 2)}"
    }
  )

}