variable "vpc-id" {
  type = string
}

variable "gateway-id" {
  type = string
}

variable "rt-usage" {
  type = string
}

variable "cidr_block"{
  type = string
  default = "0.0.0.0/0"
}
