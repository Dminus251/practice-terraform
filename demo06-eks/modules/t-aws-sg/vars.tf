variable "sg-vpc_id"{
  type = string
}

variable "ingress" {
  type = object({
    from_port = number,
    to_port = number,
    protocol = string,
    cidr_blocks = list(string),
    security_groups = list(string),
  })
}

variable "sg-name" {
  type = string
}

