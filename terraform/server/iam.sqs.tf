resource "aws_iam_role_policy_attachment" "sqs" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}