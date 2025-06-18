
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
  type    = string
  default = "Testing"
}

variable "Purpose" {
  type    = string
  default = "Private"
}

variable "Deployed-by" {
  type    = string
  default = "Senior Engineer"
}

variable "private_server_ip_index" {
  type        = number
  default     = 20
  description = "The host number used to compute private IP within the subnet."
}