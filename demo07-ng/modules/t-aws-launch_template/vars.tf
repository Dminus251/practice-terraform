variable "lt-image_id" {
  type = string
  #default = "ami-05d2438ca66594916" #ubuntu 22.04
  #default = "ami-008d41dbe16db6778" #amazon linux 2023
  default = "ami-04f3fb3944c844ddf" #eks optimized amazon linux 2023
}

variable "lt-instance_type" {
  type = string
  default = "t3.medium"
}

variable "lt-sg" {
  type = list(string)
}

variable "cluster-name"{
  type = string
}
