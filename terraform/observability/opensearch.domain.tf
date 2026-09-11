resource "aws_opensearch_domain" "this" {
  domain_name    = var.opensearch_domain.domain_name
  engine_version = var.opensearch_domain.engine_version

  cluster_config {
    instance_type            = var.opensearch_domain.cluster_config.instance_type
    instance_count           = var.opensearch_domain.cluster_config.instance_count
    dedicated_master_enabled = var.opensearch_domain.cluster_config.dedicated_master_enabled
    zone_awareness_enabled   = var.opensearch_domain.cluster_config.zone_awareness_enabled
  }

  ebs_options {
    ebs_enabled = true
    volume_type = var.opensearch_domain.ebs_options.volume_type
    volume_size = var.opensearch_domain.ebs_options.volume_size
    iops        = var.opensearch_domain.ebs_options.iops
    throughput  = var.opensearch_domain.ebs_options.throughput
  }

  domain_endpoint_options {
    enforce_https       = var.opensearch_domain.domain_endpoint_options.enforce_https
    tls_security_policy = var.opensearch_domain.domain_endpoint_options.tls_security_policy
  }

  # Pre-requisitos do fine-grained access control.
  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options {
      master_user_name     = var.opensearch_master_user.name
      master_user_password = local.opensearch_master_user_password
    }
  }

  access_policies = data.aws_iam_policy_document.opensearch_domain.json

  tags = var.tags
}
