resource "aws_launch_template" "example" {
  image_id      	 = var.lt-image_id #AMI
  instance_type 	 = var.lt-instance_type

  vpc_security_group_ids = var.lt-sg
  #user_data 		 = base64encode("#!/bin/bash\n/etc/eks/bootstrap.sh ${var.cluster-name}\n") 
  key_name 		 = var.lt-key_name
  user_data = base64encode(
    "#!/bin/bash\n/etc/eks/bootstrap.sh ${var.cluster-name}\nyum update -y\ncurl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.2/2024-07-12/bin/linux/amd64/kubectl\nchmod +x ./kubectl\n")

    #위에 userdata 되면 이것도 추가하자
    #더 보기 좋게 하는 법 없나??
    #aws configure set aws_access_key_id ${var.aws_access_key_id}\n
    #aws configure set aws_secret_access_key ${var.aws_secret_access_key}\n
    #aws configure set region ${var.region}\n
    #aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}\n
}

