
output "vpc_id" {
  description = "The ID of the VPC"
  # value       = aws_vpc.Nath-VPC
  value = aws_vpc.Nath-VPC.id
}

output "subnet_public_id" {
  description = "The ID of the public subnet"
  # value       = aws_subnet.Nath_public_subnet
  value = aws_subnet.Nath_public_subnet.id
}

output "instance_id" {
  description = "The ID of the subnet"
  # value = aws_instance.Nath_server
  value = aws_instance.Nath_Bastion_server.id
}
