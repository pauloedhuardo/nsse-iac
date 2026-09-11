resource "random_password" "opensearch_master_user" {
  length      = 24
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1

  # O OpenSearch rejeita alguns caracteres especiais na senha do master user.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  opensearch_master_user_password = coalesce(
    var.opensearch_master_user_password,
    random_password.opensearch_master_user.result
  )
}
