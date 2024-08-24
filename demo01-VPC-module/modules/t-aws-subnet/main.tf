resource "aws_subnet" "subnet-public-1" {
  vpc_id     = var.vpc-id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = "true" #퍼블릭 ip 자동 할당 기능 활성화
  #이 subnet에서 생성되는 instance에는 자동으로 publci ip가 할당된다.

  tags = {
    Name = "practice-public-1"
  }
}


resource "aws_subnet" "subnet-private-1" {
  vpc_id     = var.vpc-id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "practice-priavte-1"
  }
}

