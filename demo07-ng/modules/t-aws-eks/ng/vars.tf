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

variable "key"{
  type = string
}

variable "worker_node-name"{
  type = string
}
