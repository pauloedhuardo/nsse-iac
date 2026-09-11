resource "aws_ssm_parameter" "opensearch_master_user_name" {
  name        = var.opensearch_master_user.ssm_parameter_name
  description = "Usuario master dos dashboards do OpenSearch"
  type        = "String"
  value       = var.opensearch_master_user.name
  overwrite   = true

  tags = var.tags
}

resource "aws_ssm_parameter" "opensearch_master_user_password" {
  name        = var.opensearch_master_user.ssm_parameter_password
  description = "Senha do usuario master dos dashboards do OpenSearch"
  type        = "SecureString"
  value       = local.opensearch_master_user_password
  overwrite   = true

  tags = var.tags
}
