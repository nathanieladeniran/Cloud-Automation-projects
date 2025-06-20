variable "AWS_REGION" {
  default = "eu-north-1"
}
variable "availability_zone" {
  type    = list(string)
  default = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}
variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}
variable "instance_type" {
  default = "t3.micro"
}

variable "public_server_name" {
  default = "Quiva_Bastion_Server"
}

variable "Purpose" {
  type    = string
  default = "Public"
}

variable "Environment" {
  type    = string
  default = "Testing"
}
variable "Deployed-by" {
  type    = string
  default = "Senior Engineer"
}