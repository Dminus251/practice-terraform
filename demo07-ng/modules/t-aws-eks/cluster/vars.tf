
variable "cluster-name" {
  type = string
}
variable "cluster-role_arn" {
  type = string
}

variable "cluster-subnet_ids" {
  type = list(string)
}
