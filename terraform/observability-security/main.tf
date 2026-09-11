terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  backend "s3" {
    bucket       = "nsse-terraform-state-files-p"
    key          = "observability-security/terraform.tfstate"
    use_lockfile = true
    region       = "us-east-1"
  }
}

provider "aws" {
  region = var.region

  assume_role {
    role_arn    = var.assume_role.role_arn
    external_id = var.assume_role.external_id
  }
}

locals {
  # Sem isto o provider pinga o cluster para descobrir a versao, e o timeout
  # padrao desse ping e de 5s - curto demais logo apos o apply, enquanto o
  # t3.small ainda esta esquentando (medido: 1,6s ja aquecido, mas o primeiro
  # apply falhou nos tres recursos por timeout). Derivado do data source para
  # nao dessincronizar de engine_version na stack observability.
  opensearch_version = "${split("_", data.aws_opensearch_domain.this.engine_version)[1]}.0"
}

# O endpoint e a senha vem de data sources, entao ja sao conhecidos no plan.
# E por isso que esta stack e separada da observability: configurar este
# provider a partir de um recurso do mesmo apply deixaria o plan indefinido.
provider "opensearch" {
  url      = "https://${data.aws_opensearch_domain.this.endpoint}"
  username = data.aws_ssm_parameter.master_user_name.value
  password = data.aws_ssm_parameter.master_user_password.value

  opensearch_version = local.opensearch_version

  sign_aws_requests = false # obrigatorio para basic auth
  healthcheck       = false # nao funciona em dominio gerenciado
}
