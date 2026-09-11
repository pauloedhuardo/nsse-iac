# Provider OIDC do GitHub Actions. E um recurso global da conta - a AWS aceita
# apenas um por URL - entao ele mora aqui, no modulo de infraestrutura de longa
# duracao, e o modulo site o consulta via data source
# (site/data.iam.identity-provider.github.tf).
#
# Ele ja morou no site. Um destroy daquele modulo levou o provider junto e deixou
# o role de backend com um Principal.Federated orfao, quebrando o CD. Por isso a
# ownership mudou de lado: o server nao deve depender do ciclo de vida do frontend.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  tags = var.tags
}
