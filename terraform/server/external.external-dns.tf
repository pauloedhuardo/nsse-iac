data "aws_iam_policy_document" "external_dns_policy" {
  statement {
    effect = "Allow"

    resources = ["arn:aws:route53:::hostedzone/*"]
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResources"
    ]
  }

  statement {
    effect = "Allow"

    resources = ["*"]
    actions = [
      "route53:ListHostedZones"
    ]
  }
}

resource "aws_iam_policy" "external_dns_policy" {
  name   = var.external_dns.policy_name
  policy = data.aws_iam_policy_document.external_dns_policy.json
}

resource "aws_iam_role_policy_attachment" "external_dns_policy" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.external_dns_policy.arn
}