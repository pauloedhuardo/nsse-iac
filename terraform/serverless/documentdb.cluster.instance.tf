resource "aws_docdb_cluster_instance" "this" {
  identifier         = var.documentdb_cluster.instance.identifier
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.documentdb_cluster.instance.class
}