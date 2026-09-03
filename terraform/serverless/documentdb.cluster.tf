resource "aws_docdb_cluster" "this" {
  cluster_identifier              = var.documentdb_cluster.cluster_identifier
  engine                          = var.documentdb_cluster.engine
  master_username                 = var.documentdb_cluster.master_username
  manage_master_user_password     = true
  backup_retention_period         = var.documentdb_cluster.backup_retention_period
  preferred_backup_window         = var.documentdb_cluster.preferred_backup_window
  preferred_maintenance_window    = var.documentdb_cluster.preferred_maintenance_window
  final_snapshot_identifier       = "${var.documentdb_cluster.final_snapshot_identifier}-${local.final_snapshot_suffix}"
  storage_encrypted               = var.documentdb_cluster.storage_encrypted
  vpc_security_group_ids          = [aws_security_group.documentdb.id]
  db_subnet_group_name            = aws_docdb_subnet_group.this.name
  availability_zones              = var.documentdb_cluster.availability_zones
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.this.name
  enabled_cloudwatch_logs_exports = var.documentdb_cluster.enabled_cloudwatch_logs_exports

  lifecycle {
    ignore_changes = [availability_zones]
  }

  tags = var.tags
}