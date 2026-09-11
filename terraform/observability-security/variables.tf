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

# Precisa bater com a stack observability.
variable "opensearch_domain_name" {
  type    = string
  default = "nsse-observability"
}

variable "opensearch_master_user" {
  type = object({
    ssm_parameter_name     = string
    ssm_parameter_password = string
  })

  default = {
    ssm_parameter_name     = "/nsse/observability/opensearch/master-user/name"
    ssm_parameter_password = "/nsse/observability/opensearch/master-user/password"
  }
}

variable "opensearch_logs_reader" {
  type = object({
    role_name              = string
    user_name              = string
    index_patterns         = list(string)
    masked_fields          = list(string)
    ssm_parameter_password = string
  })

  default = {
    role_name              = "nsse_logs_reader"
    user_name              = "nsseViewer"
    index_patterns         = ["nsse-logs-*"]
    masked_fields          = ["client_ip"]
    ssm_parameter_password = "/nsse/observability/opensearch/logs-reader/password"
  }
}

variable "opensearch_logs_writer" {
  type = object({
    role_name      = string
    index_patterns = list(string)

    # Roles IAM mapeadas como backend role. Nao precisam existir no momento do
    # apply: o security plugin guarda o ARN como string. O default e a role das
    # instancias do cluster, usada por um agente de coleta rodando nos nodes.
    backend_role_names = list(string)
  })

  default = {
    role_name          = "nsse_logs_writer"
    index_patterns     = ["nsse-logs-*"]
    backend_role_names = ["nsse-production-instance-role"]
  }
}

# Role interna do OpenSearch que da acesso ao proprio Dashboards. Sem ela o
# usuario autentica mas nao consegue abrir a interface.
variable "opensearch_dashboards_user_role" {
  type    = string
  default = "opensearch_dashboards_user"
}
