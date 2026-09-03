resource "aws_docdb_cluster_parameter_group" "this" {
  family = var.documentdb_cluster.parameter_group.family
  name   = var.documentdb_cluster.parameter_group.name

  parameter {
    name  = "audit_logs"
    value = "enabled"
  }

  parameter {
    name  = "profiler"
    value = "enabled"
  }
}