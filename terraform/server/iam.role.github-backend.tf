resource "aws_iam_role" "github_backend" {
  name = "nsse-github-backend-role"

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
          # Mesmo subject imutavel do role de frontend: o repositorio foi criado
          # depois de 15/07/2026, entao o GitHub embute o id do dono (81598234) e
          # o id do repositorio (1357313343) no claim.
          #
          # Diferente do frontend, que usa ":*", aqui o escopo termina em
          # ":environment:production". Os tres jobs que assumem este role
          # (build-and-push e update-gitops no CD, e rollback) declaram
          # environment: production, entao o claim casa. Um job novo que precise
          # deste role e nao declare o environment falhara no
          # AssumeRoleWithWebIdentity - o que e proposital, mas e a primeira coisa
          # a conferir se aparecer "Not authorized to perform sts:AssumeRole...".
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:pauloedhuardo@81598234/not-so-simple-ecommerce@1357313343:environment:production"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "github_backend" {
  name = "github-backend-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        # GetAuthorizationToken e uma acao de conta e nao aceita recurso; e o que
        # o aws-actions/amazon-ecr-login chama para trocar as credenciais do role
        # pelo token de docker login.
        "Sid" : "EcrAuth",
        "Effect" : "Allow",
        "Action" : "ecr:GetAuthorizationToken",
        "Resource" : "*"
      },
      {
        # Restrito aos repositorios criados neste modulo.
        "Sid" : "EcrPushPull",
        "Effect" : "Allow",
        "Action" : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          # DescribeImages e usada pelo rollback-backend.yml para confirmar que a
          # tag de destino ainda existe antes de commitar no gitops.
          "ecr:DescribeImages"
        ],
        "Resource" : aws_ecr_repository.these[*].arn
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "github_backend" {
  role       = aws_iam_role.github_backend.name
  policy_arn = aws_iam_policy.github_backend.arn
}
