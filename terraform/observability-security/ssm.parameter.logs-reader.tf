resource "aws_ssm_parameter" "logs_reader_password" {
  name        = var.opensearch_logs_reader.ssm_parameter_password
  description = "Senha do usuario somente leitura dos dashboards do OpenSearch"
  type        = "SecureString"
  value       = random_password.logs_reader.result
  overwrite   = true

  tags = var.tags
}
