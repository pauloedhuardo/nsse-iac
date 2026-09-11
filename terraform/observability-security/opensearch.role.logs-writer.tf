resource "opensearch_role" "logs_writer" {
  role_name   = var.opensearch_logs_writer.role_name
  description = "Escrita nos indices de log do nsse"

  cluster_permissions = ["cluster_composite_ops", "cluster_monitor"]

  index_permissions {
    index_patterns  = var.opensearch_logs_writer.index_patterns
    allowed_actions = ["crud", "create_index", "indices:admin/mapping/put"]
  }
}
