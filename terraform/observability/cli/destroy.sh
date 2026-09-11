#!/usr/bin/env bash
#
# Derruba a observabilidade em dois passos, na ordem inversa do apply.
#
# Por que dois: as roles, o usuario e os role mappings vivem DENTRO do cluster,
# nao na API da AWS. Se o dominio for destruido primeiro, o provider opensearch
# fica sem ninguem para conversar e o destroy da observability-security trava no
# data source do dominio - state orfao, que so sai na mao.
#
#   passo 1 - destroy da observability-security (objetos dentro do cluster).
#   passo 2 - destroy da observability (o dominio em si).
#
# Se o dominio ja tiver sumido antes do passo 1 (destroy manual, ou um ciclo que
# morreu no meio), os objetos de dentro dele tambem ja morreram. Nesse caso o
# script tira esses recursos do state em vez de tentar deleta-los num cluster
# que nao existe mais, e segue destruindo o que sobrou na AWS.
#
# Uso: ./destroy.sh [args extras do terraform, ex: -auto-approve]
#
set -euo pipefail

TERRAFORM_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DOMAIN_STACK="$TERRAFORM_DIR/observability"
SECURITY_STACK="$TERRAFORM_DIR/observability-security"

DOMAIN_NAME="${OPENSEARCH_DOMAIN_NAME:-nsse-observability}"

echo "==> passo 1/2: destruindo roles, usuario e role mappings"

terraform -chdir="$SECURITY_STACK" init -input=false

if ! terraform -chdir="$SECURITY_STACK" state list >/dev/null 2>&1 ||
  [[ -z "$(terraform -chdir="$SECURITY_STACK" state list 2>/dev/null)" ]]; then
  echo "    state vazio, nada a destruir."
elif aws opensearch describe-domain --domain-name "$DOMAIN_NAME" >/dev/null 2>&1; then
  terraform -chdir="$SECURITY_STACK" destroy "$@"
else
  echo "    o dominio $DOMAIN_NAME nao existe mais; os objetos de dentro dele"
  echo "    foram embora junto. removendo do state:"

  while read -r resource; do
    [[ -z "$resource" ]] && continue
    echo "      $resource"
    terraform -chdir="$SECURITY_STACK" state rm "$resource" >/dev/null
  done < <(terraform -chdir="$SECURITY_STACK" state list | grep '^opensearch_' || true)

  echo "    destruindo o que sobrou na AWS."
  terraform -chdir="$SECURITY_STACK" destroy "$@"
fi

echo
echo "==> passo 2/2: destruindo o dominio OpenSearch"
terraform -chdir="$DOMAIN_STACK" init -input=false
terraform -chdir="$DOMAIN_STACK" destroy "$@"

echo
echo "==> observabilidade derrubada."
