output "opensearch_dashboards_url" {
  value = "https://${data.aws_opensearch_domain.this.dashboard_endpoint}"
}

output "opensearch_logs_reader_user_name" {
  value = opensearch_user.logs_reader.username
}

output "opensearch_logs_reader_password_parameter" {
  value = aws_ssm_parameter.logs_reader_password.name
}

output "opensearch_logs_reader_password" {
  value     = random_password.logs_reader.result
  sensitive = true
}

output "opensearch_logs_writer_backend_roles" {
  value = local.logs_writer_backend_roles
}

output "opensearch_retention_policies" {
  value = {
    for name, policy in var.opensearch_retention :
    opensearch_ism_policy.retention[name].policy_id => policy.min_index_age
  }
}
