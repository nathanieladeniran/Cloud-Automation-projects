output "vpc_id" {
  description = "The ID of the VPC"
  # value       = aws_vpc.Nath-VPC
  value = aws_vpc.Quiva-VPC.id
}

output "subnet_public_id" {
  description = "The ID of the public subnet"
  # value       = aws_subnet.Nath_public_subnet
  value = [for s in aws_subnet.Quiva_public_subnet : s.id]
}

output "subnet_private_id" {
  description = "The ID of the public subnet"
  # value       = aws_subnet.Nath_public_subnet
  value = [for p in aws_subnet.Quiva_private_subnet : p.id]
}
output "instance_id" {
  description = "The ID of the subnet"
  # value = aws_instance.Nath_server
  value = aws_instance.Quiva_Bastion_server.id
}

output "rds_endpoint" {
  description = "Endpoint of RDS created"
  value       = aws_db_instance.private_db_instance.endpoint
}