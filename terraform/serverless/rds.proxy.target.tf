resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }

  lifecycle {
    # aws_db_proxy.this.id e o NOME do proxy (var.rds_proxy.name), que e
    # estatico e nao muda quando o proxy e recriado -- o trigger nunca
    # disparava. O arn carrega o id gerado (prx-...), esse sim muda.
    replace_triggered_by = [aws_db_proxy.this.arn]
  }
}

resource "aws_db_proxy_target" "this" {
  db_cluster_identifier = aws_rds_cluster.this.cluster_identifier
  db_proxy_name         = aws_db_proxy.this.name
  target_group_name     = aws_db_proxy_default_target_group.main.name

  # registrar um TRACKED_CLUSTER exige instancias disponiveis no cluster;
  # sem isso o registro corre junto com a criacao das instancias.
  depends_on = [aws_rds_cluster_instance.this]

  lifecycle {
    # destruir o cluster desregistra o target no lado da AWS, mas
    # cluster_identifier e estavel entre recriacoes, entao o Terraform nao
    # enxergava mudanca e o state ficava apontando para um target inexistente.
    # cluster_resource_id (cluster-XXXX) muda a cada recriacao.
    replace_triggered_by = [
      aws_db_proxy.this.arn,
      aws_rds_cluster.this.cluster_resource_id,
    ]
  }
}