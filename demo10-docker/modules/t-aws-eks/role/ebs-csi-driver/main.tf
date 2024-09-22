#Role for Ebs-Csi-Driver
resource "aws_iam_role" "ecd-role" {
  name = var.role-ecd_role_name

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::992382518527:oidc-provider/${var.role-ecd-oidc_without_https}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${var.role-ecd-oidc_without_https}:aud": "sts.amazonaws.com", #인증 요청 대상
 		    "${var.role-ecd-oidc_without_https}:sub": "system:serviceaccount:${var.role-ecd-namespace}:${var.role-ecd-sa_name}"
                }
            }
        }
    ] 
  })
}
resource "aws_iam_role_policy_attachment" "alb_ingress_policy_attach" {
  role = aws_iam_role.ecd-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  depends_on = [aws_iam_role.ecd-role]
}
