data "aws_iam_policy_document" "opensearch_domain" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["es:ESHttp*"]

    resources = [
      "arn:aws:es:${var.region}:${data.aws_caller_identity.this.account_id}:domain/${var.opensearch_domain.domain_name}/*"
    ]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.opensearch_allowed_cidr_blocks
    }
  }
}
