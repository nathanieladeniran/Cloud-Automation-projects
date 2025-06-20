# ALl variable to be used in the VPC
variable "cidr_block" {
    description = "CIDR for the vpc"
}

variable "vpc_name" {
  description = "The Name tag for the VPC"
}

variable "tags" {
  description = "Common Tags for all resources"
  type        = map(string)
  default     = {}
}