variable "region" {
  type    = string
  default = "us-east-1"
}

variable "tags" {
  type = object({
    Project     = string
    Environment = string
  })

  default = {
    Project     = "nsse"
    Environment = "production"
  }
}

variable "assume_role" {
  type = object({
    role_arn    = string
    external_id = string
  })

  default = {
    role_arn    = "arn:aws:iam::495624154773:role/terraform-role"
    external_id = "dc584012-b106-4605-9973-189dc02048c2"
  }
}

variable "opensearch_domain" {
  type = object({
    domain_name    = string
    engine_version = string

    cluster_config = object({
      instance_type            = string
      instance_count           = number
      dedicated_master_enabled = bool
      zone_awareness_enabled   = bool
    })

    ebs_options = object({
      volume_type = string
      volume_size = number
      iops        = number
      throughput  = number
    })

    domain_endpoint_options = object({
      enforce_https       = bool
      tls_security_policy = string
    })
  })

  # t3.small.search e o menor tipo que ainda suporta encryption at rest,
  # requisito do fine-grained access control (usuario e senha nos dashboards).
  # gp3 no t3.small.search: minimo de 10 GB, 3000 IOPS e 125 MB/s.
  default = {
    domain_name    = "nsse-observability"
    engine_version = "OpenSearch_2.19"

    cluster_config = {
      instance_type            = "t3.small.search"
      instance_count           = 1
      dedicated_master_enabled = false
      zone_awareness_enabled   = false
    }

    ebs_options = {
      volume_type = "gp3"
      volume_size = 10
      iops        = 3000
      throughput  = 125
    }

    domain_endpoint_options = {
      enforce_https       = true
      tls_security_policy = "Policy-Min-TLS-1-2-PFS-2023-10"
    }
  }
}

variable "opensearch_master_user" {
  type = object({
    name                   = string
    ssm_parameter_name     = string
    ssm_parameter_password = string
  })

  default = {
    name                   = "nsseAdmin"
    ssm_parameter_name     = "/nsse/observability/opensearch/master-user/name"
    ssm_parameter_password = "/nsse/observability/opensearch/master-user/password"
  }
}

# Deixe null para que a senha seja gerada e gravada no Parameter Store.
variable "opensearch_master_user_password" {
  type      = string
  sensitive = true
  default   = null
}

# O dominio tem endpoint publico para que os dashboards sejam acessiveis pelo
# navegador; toda requisicao ainda precisa autenticar no banco de usuarios
# interno. Restrinja aqui se quiser limitar a origem das requisicoes.
variable "opensearch_allowed_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
