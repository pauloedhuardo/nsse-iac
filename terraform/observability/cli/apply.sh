#!/usr/bin/env bash
#
# Cria a observabilidade em dois passos.
#
# Por que dois: a stack observability-security configura o provider opensearch
# a partir do endpoint do dominio e da senha do master user. Provider so pode
# ser configurado com valores conhecidos no plan, e o endpoint so existe depois
# que o dominio sobe. Por isso as duas stacks sao separadas e aplicadas em
# sequencia - a segunda le o endpoint por data source, ja resolvido.
#
#   passo 1 - cria o dominio OpenSearch e o master user.
#   passo 2 - cria roles, usuario de leitura e role mappings dentro do cluster.
#
# O passo 1 demora: criar um dominio gerenciado leva de 10 a 20 minutos, e o
# terraform so retorna quando o dominio sai de Processing.
#
# Uso: ./apply.sh [args extras do terraform, ex: -auto-approve]
#
set -euo pipefail

TERRAFORM_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DOMAIN_STACK="$TERRAFORM_DIR/observability"
SECURITY_STACK="$TERRAFORM_DIR/observability-security"

echo "==> passo 1/2: criando o dominio OpenSearch (pode levar de 10 a 20 min)"
terraform -chdir="$DOMAIN_STACK" init -input=false
terraform -chdir="$DOMAIN_STACK" apply "$@"

echo
echo "==> passo 2/2: aplicando roles, usuario e role mappings"
terraform -chdir="$SECURITY_STACK" init -input=false
terraform -chdir="$SECURITY_STACK" apply "$@"

echo
echo "==> observabilidade pronta."
echo "    dashboards: $(terraform -chdir="$DOMAIN_STACK" output -raw opensearch_dashboards_url)"
echo
echo "    as senhas sao novas a cada ciclo e ficam no Parameter Store:"
echo "      aws ssm get-parameter --with-decryption --output text --query Parameter.Value \\"
echo "        --name $(terraform -chdir="$DOMAIN_STACK" output -raw opensearch_master_user_password_parameter)"
echo "      aws ssm get-parameter --with-decryption --output text --query Parameter.Value \\"
echo "        --name $(terraform -chdir="$SECURITY_STACK" output -raw opensearch_logs_reader_password_parameter)"
echo
echo "    para derrubar, use ./destroy.sh (um destroy direto na observability"
echo "    deixa a observability-security com state orfao)."
