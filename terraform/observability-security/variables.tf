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
    index_patterns         = ["nsse-logs-*", "nsse-metrics-*"]
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
    index_patterns     = ["nsse-logs-*", "nsse-metrics-*"]
    backend_role_names = ["nsse-production-instance-role"]
  }
}

# Role interna do OpenSearch que da acesso ao proprio Dashboards. Sem ela o
# usuario autentica mas nao consegue abrir a interface.
variable "opensearch_dashboards_user_role" {
  type    = string
  default = "opensearch_dashboards_user"
}

# Retencao por indice. O dominio e um t3.small.search de no unico com 10 GB de
# EBS: sem ISM os indices diarios so crescem e o disco enche. min_index_age
# conta da criacao do indice, nao da idade do documento.
variable "opensearch_retention" {
  type = map(object({
    index_patterns = list(string)
    min_index_age  = string
    priority       = number
  }))

  default = {
    logs = {
      index_patterns = ["nsse-logs-*"]
      min_index_age  = "7d"
      priority       = 100
    }

    # Metricas geram muito mais documentos por dia que logs, entao saem antes.
    metrics = {
      index_patterns = ["nsse-metrics-*"]
      min_index_age  = "3d"
      priority       = 110
    }
  }
}

# Sem template, o OpenSearch cria os indices diarios com 5 shards e 1 replica.
# Num dominio de no unico a replica nunca e atribuida (cluster fica yellow para
# sempre) e 5 shards para um indice de poucos MB so gasta heap -- o t3.small
# tem ~1 GB e o limite pratico dele e contagem de shard, nao disco.
variable "opensearch_index_templates" {
  type = map(object({
    index_patterns     = list(string)
    priority           = number
    number_of_shards   = number
    number_of_replicas = number
    refresh_interval   = string

    # Mapeia todo campo string sob attributes.* como keyword. Sem isto o mapping
    # dinamico gera text + subcampo .keyword: filtrar funciona, mas agregar
    # exige o sufixo (senao "Fielddata is disabled") e cada atributo e indexado
    # duas vezes. Os atributos de metrica -- namespace, pod, deployment, node --
    # sao todos identificadores, nunca texto para busca livre.
    keyword_attributes = bool

    properties = map(object({
      type  = string
      index = optional(bool, true)
    }))
  }))

  default = {
    logs = {
      index_patterns     = ["nsse-logs-*"]
      priority           = 100
      number_of_shards   = 1
      number_of_replicas = 0
      refresh_interval   = "30s"

      # Log nao tem attributes.*; os campos vem do fluent-bit.
      keyword_attributes = false

      # Os campos de log vem do fluent-bit e variam por aplicacao; o mapping
      # dinamico da conta. Aqui interessam so os settings.
      properties = {}
    }

    metrics = {
      index_patterns     = ["nsse-metrics-*"]
      priority           = 110
      number_of_shards   = 1
      number_of_replicas = 0
      refresh_interval   = "30s"

      keyword_attributes = true

      # O mapping dinamico faz de name/kind/unit texto analisado, o que obriga
      # a agregar por name.keyword e gasta espaco a toa. E deixa value como
      # float, que perde precisao em contadores de bytes.
      properties = {
        name        = { type = "keyword" }
        kind        = { type = "keyword" }
        unit        = { type = "keyword" }
        serviceName = { type = "keyword" }
        value       = { type = "double" }
        time        = { type = "date" }
        startTime   = { type = "date" }

        # Texto fixo por metrica, repetido em todo documento. Guardado para
        # leitura, fora do indice invertido.
        description = { type = "text", index = false }
      }
    }
  }
}
