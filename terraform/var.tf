
variable "AWS_REGION" {
  default = "us-east-1"
}

variable "availability_zone" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "Environment" {
  type    = list(string)
  default = ["test", "staging", "production"]
}

variable "Purpose" {
  type    = list(string)
  default = ["private", "public"]
}

variable "Deployed-by" {
  type    = list(string)
  default = ["Enigneer", "Senior Engineer"]
}

variable "private_server_ip_index" {
  type        = number
  default     = 20
  description = "The host number used to compute private IP within the subnet."
}