variable "region" {
  default = "us-east-1"
}

variable "env" {
  default = "Nikhil-Beacon"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "azs" {
  type = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
