data "aws_iam_policy_document" "ecr_pull" {
  statement {
    effect = "Allow"

    resources = ["*"]
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage"
    ]
  }
}

resource "aws_iam_policy" "ecr_pull" {
  name   = var.ecr_pull.policy_name
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "ecr_pull" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.ecr_pull.arn
}
