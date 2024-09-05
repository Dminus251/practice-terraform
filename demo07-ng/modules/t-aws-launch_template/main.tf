resource "aws_launch_template" "example" {
  image_id      	 = var.lt-image_id #AMI
  instance_type 	 = var.lt-instance_type

  vpc_security_group_ids = var.lt-sg
  user_data 		 = base64encode("#!/bin/bash\n/etc/eks/bootstrap.sh ${var.cluster-name}\n") 
  key_name 		 = var.lt-key_name
}

