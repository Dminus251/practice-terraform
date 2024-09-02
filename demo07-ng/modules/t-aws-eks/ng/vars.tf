variable "cluster-name"{
  type = string
}

variable "ng-name"{
  type = string
}

variable "ng-role_arn"{
  type = string
}


variable "subnet-id"{
  type = list(string)
}

variable "ng-lt_id"{
  description = "id of launch template for node group"
  type = string
}
