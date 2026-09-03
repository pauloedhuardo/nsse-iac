resource "aws_docdb_subnet_group" "this" {
  name       = var.subnet_group.documentdb
  subnet_ids = data.aws_subnets.private_subnets.ids

  tags = merge(var.tags, {
    Name = var.subnet_group.documentdb
  })
}