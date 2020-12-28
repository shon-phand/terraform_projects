#creating a user without any permission

resource "aws_iam_user" "users" {
  name = "shon"
  tags = {
    "role" = "admin"
    "area" = "ec2"
  }
}

# creating a policy

# resource "aws_iam_user_policy" "ec-access-policy" {
#   policy = file("./vpc-ec2FullPolicy.json")
#   user = "cloud_user"
#   name = "ec-access-policy"
# }


# attaching a full EC2 admin policy to user

resource "aws_iam_user_policy_attachment" "ec2-policy-attachement" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  user = aws_iam_user.users.name

}

resource "aws_iam_user_policy_attachment" "s3-policy-attachement" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  user = aws_iam_user.users.name

}