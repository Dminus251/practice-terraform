variable "private_subnet-length" {
  type = number
}

variable "eip-id" {
  type = list(string)
}

variable "private_subnet-id" {
  type = list(string)
}

variable "nat-name" {
  type = string
  default = "practice-nat"
}

