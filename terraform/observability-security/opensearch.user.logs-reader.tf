resource "opensearch_user" "logs_reader" {
  username    = var.opensearch_logs_reader.user_name
  password    = random_password.logs_reader.result
  description = "Usuario somente leitura dos dashboards"
}
