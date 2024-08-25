variable "vpc-id" {
  type = string
}

variable "public_subnets" {
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
  }))
  
  default = {
    "practice-public-1" = {
      cidr_block	= "10.0.1.0/24"
      availability_zone = "ap-northeast-2a"
      map_public_ip_on_launch = true
    }
  }
}
