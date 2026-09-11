locals {
  logs_writer_backend_roles = [
    for name in var.opensearch_logs_writer.backend_role_names :
    "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${name}"
  ]
}

resource "opensearch_roles_mapping" "logs_writer" {
  role_name     = opensearch_role.logs_writer.id
  description   = "Roles IAM autorizadas a escrever logs"
  backend_roles = local.logs_writer_backend_roles
}
