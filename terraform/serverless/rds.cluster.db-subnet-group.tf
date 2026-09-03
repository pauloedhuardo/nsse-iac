resource "aws_db_subnet_group" "this" {
  name       = var.subnet_group.db
  subnet_ids = data.aws_subnets.private_subnets.ids

  tags = merge(var.tags, {
    Name = var.subnet_group.db
  })
}