# O provider OIDC do GitHub Actions e criado no modulo server
# (server/iam.identity-provider.github.tf), por ser um recurso global da conta.
# Aqui ele e apenas consultado. Aplique o server antes do site em uma conta nova.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
