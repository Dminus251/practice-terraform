resource "aws_launch_template" "example" {
  image_id      	 = var.lt-image_id #AMI
  instance_type 	 = var.lt-instance_type

  vpc_security_group_ids = var.lt-sg
  key_name 		 = var.lt-key_name
  default_version	 = "1"
  user_data = base64encode(<<EOF
	#!/bin/bash
	/etc/eks/bootstrap.sh ${var.cluster-name}
	yum update -y &&
	curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.2/2024-07-12/bin/linux/amd64/kubectl &&
	chmod +x ./kubectl &&
	mv ./kubectl /usr/local/bin/ &&
	aws configure set aws_access_key_id ${var.aws_access_key_id} &&
	aws configure set aws_secret_access_key ${var.aws_access_key_secret} &&
	aws configure set region ${var.region} &&
	aws eks update-kubeconfig --region ${var.region} --name ${var.cluster-name}
	EOF
	)
}
