variable "AWS_ACCESS_KEY" {
}

variable "AWS_SECRET_KEY" {
}

variable "AWS_REGION" {
  default = "ap-northeast-2"
}

variable "DOMAIN" {
}

# ###########PUBLIC SUBNET############
variable "public_subnet-cidr" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "public_subnet-az" {
  type = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet-name"{
  type = list(string)
  default = ["public-2a", "public-2c"]
}

# ###########PRIVATE SUBNET############
variable "private_subnet-cidr" {
  type = list(string)
  default = ["10.0.0.0/24", "10.0.2.0/24"]
}

variable "private_subnet-az" {
  type = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "private_subnet-name" {
  type = list(string)
  default = ["private-2a", "private-2c"]
}


# ###########SECURITY GROUP############
variable "sg-ingress" {
  type = object({
    from_port       = number,
    to_port         = number,
    protocol        = string,
    cidr_blocks     = list(string),
    security_groups = list(string),
  })
  default = {
   
      from_port       = 22,
      to_port         = 22,
      protocol        = "tcp",  
      cidr_blocks     = ["0.0.0.0/0"],
      security_groups = []
  }
}

#eks cluser name
variable "cluster-name" {
  type = string
  default = "yyk-cluster"
}
