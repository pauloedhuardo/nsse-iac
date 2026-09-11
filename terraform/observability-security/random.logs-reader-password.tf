resource "random_password" "logs_reader" {
  length      = 24
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1

  # O OpenSearch rejeita alguns caracteres especiais na senha do usuario.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
