resource "aws_iam_role" "github_frontend" {
  name = "nsse-github-frontend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          # GitHub emits the immutable subject claim, which carries the owner id
          # (81598234) and the repository id (1357313343) instead of names only:
          # repo:pauloedhuardo@81598234/not-so-simple-ecommerce@1357313343:environment:staging
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:pauloedhuardo@81598234/not-so-simple-ecommerce@1357313343:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })
}

resource "aws_iam_policy" "github_frontend" {
  name = "github-frontend-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*",
          aws_s3_bucket.staging_site.arn,
          "${aws_s3_bucket.staging_site.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:UpdateDistribution",
          "cloudfront:ListDistributions"
        ],
        "Resource" : [
          aws_cloudfront_distribution.this.arn,
          aws_cloudfront_distribution.staging.arn
        ]
      }
    ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "github_frontend" {
  role       = aws_iam_role.github_frontend.name
  policy_arn = aws_iam_policy.github_frontend.arn
}