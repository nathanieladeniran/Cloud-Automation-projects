
variable "ami" {
  description = "The Amazon Image that will be used to create the elastic compute cloud"
  default = ""
}
variable "instance_type" {
  description = "Instance type to be used by the AMI"
  default = ""
}
variable "name" {
    description = "Name of the EC2"
}

variable "tags" {
  description = "value"
  type = map(string)
  default = { }
}

variable "key_name" {
  description = "Pem key for the instance"
}