output "opensearch_domain_endpoint" {
  value = aws_opensearch_domain.this.endpoint
}

output "opensearch_dashboards_url" {
  value = "https://${aws_opensearch_domain.this.dashboard_endpoint}"
}

output "opensearch_master_user_name" {
  value = var.opensearch_master_user.name
}

output "opensearch_master_user_password_parameter" {
  value = aws_ssm_parameter.opensearch_master_user_password.name
}

output "opensearch_master_user_password" {
  value     = local.opensearch_master_user_password
  sensitive = true
}
