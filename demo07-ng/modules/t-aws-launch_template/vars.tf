variable "lt-image_id" {
  type = string
  default = "ami-05d2438ca66594916" #ubuntu 22.04
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
