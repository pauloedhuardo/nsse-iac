resource "opensearch_role" "logs_reader" {
  role_name   = var.opensearch_logs_reader.role_name
  description = "Leitura dos indices de log do nsse"

  cluster_permissions = ["cluster_composite_ops_ro"]

  index_permissions {
    index_patterns  = var.opensearch_logs_reader.index_patterns
    allowed_actions = ["read", "search"]
    masked_fields   = var.opensearch_logs_reader.masked_fields
  }

  tenant_permissions {
    tenant_patterns = ["global_tenant"]
    allowed_actions = ["kibana_all_read"]
  }
}
