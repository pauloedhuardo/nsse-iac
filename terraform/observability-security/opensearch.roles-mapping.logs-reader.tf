resource "opensearch_roles_mapping" "logs_reader" {
  role_name   = opensearch_role.logs_reader.id
  description = "Usuarios de leitura dos logs"
  users       = [opensearch_user.logs_reader.id]
}

# Sem este mapping o usuario autentica mas o Dashboards nao abre, porque falta
# acesso ao indice interno do proprio Dashboards.
resource "opensearch_roles_mapping" "dashboards_user" {
  role_name   = var.opensearch_dashboards_user_role
  description = "Acesso a interface do Dashboards"
  users       = [opensearch_user.logs_reader.id]
}
