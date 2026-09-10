# O provider OIDC do GitHub Actions e criado no modulo site
# (site/iam.identity-provider.github.tf). Aqui ele e apenas consultado, para que
# o role de backend confie na mesma federacao sem duplicar o recurso.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
