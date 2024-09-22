
variable "cluster-name" {
  type = string
}

variable "cluster-sg" {
  type = list(string)
}


variable "cluster-role_arn" {
  type = string
}

variable "cluster-subnet_ids" {
  type = list(string)
}
