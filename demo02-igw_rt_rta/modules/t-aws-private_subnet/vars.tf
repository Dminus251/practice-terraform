variable "vpc-id" {
  type = string
}

variable "private_subnets" {
  type = map(object({
    cidr_block              = string
    availability_zone       = string
  }))
  
  default = {
    "private-subnet-1" = {
      cidr_block	= "10.0.2.0/24"
      availability_zone = "ap-northeast-2a"
    }
  }
}
