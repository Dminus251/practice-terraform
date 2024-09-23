variable "rds-allocated_storage"{
  type = number
}

variable "rds-db_name"{
  type = string
}
variable "rds-engine"{
  type = string
}
variable "rds-engine_version"{
  type = string
}
variable "rds-instance_class"{
  type = string
}
variable "rds-username"{
  type = string
}
variable "rds-password"{
  type = string
}

variable "rds-skip_final_snapshot"{
  type = string
  default = true
}
