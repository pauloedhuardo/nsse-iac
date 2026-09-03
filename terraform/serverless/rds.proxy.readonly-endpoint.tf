resource "aws_db_proxy_endpoint" "read_only" {
  db_proxy_name          = aws_db_proxy.this.name
  db_proxy_endpoint_name = var.rds_proxy.read_only_endpoint.name
  vpc_subnet_ids         = data.aws_subnets.private_subnets.ids
  vpc_security_group_ids = [aws_security_group.postgresql.id]
  target_role            = var.rds_proxy.read_only_endpoint.target_role
}