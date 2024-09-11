resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list = var.client_id_list
  url = var.url
  thumbprint_list = ["55635cfea6a15f4770cc5ec0977492b318f9b0cc"]  # AWS의 OIDC thumbprint
  #아래 명령으로 나온 값이며, 고정값이라고 함
  #echo | openssl s_client -connect oidc.eks.ap-northeast-2.amazonaws.com:443 2>/dev/null | openssl x509 -fingerprint -noout | sed 's/://g' | awk -F'=' '{print tolower($2)}'
}
