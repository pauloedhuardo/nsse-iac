#!/usr/bin/env bash
#
# Derruba o modulo site em dois passos.
#
# Por que dois: a AWS recusa deletar uma continuous deployment policy que esteja
# anexada a uma distribuicao primaria ("You cannot delete a continuous deployment
# policy that's attached to a primary distribution"). O attach precisa ser
# desfeito antes do destroy.
#
# Por que o detach sai pela AWS CLI e nao pelo terraform: o atributo
# continuous_deployment_policy_id e Optional+Computed no provider. Passar null ou
# "" faz o terraform tratar o campo como nao-gerenciado e PRESERVAR o valor do
# servidor - um apply com attach=false da "0 changed" e nao desanexa nada
# (testado). So o UpdateDistribution direto remove a associacao.
#
#   passo 1 - desanexa a policy via AWS CLI (no-op se ja estiver desanexada).
#   passo 2 - destroy normal.
#
# Uso: ./destroy.sh [args extras do terraform, ex: -auto-approve]
#
set -euo pipefail

cd "$(dirname "$0")"

echo "==> passo 1/2: desanexando a continuous deployment policy"

DIST_ID="$(terraform output -raw cloudfront_distribution_id 2>/dev/null || true)"

if [[ -z "$DIST_ID" ]]; then
  echo "    distribuicao nao existe no state, nada a desanexar."
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  aws cloudfront get-distribution-config --id "$DIST_ID" > "$TMP/get.json"
  ETAG="$(jq -r '.ETag' "$TMP/get.json")"
  POLICY="$(jq -r '.DistributionConfig.ContinuousDeploymentPolicyId // ""' "$TMP/get.json")"

  if [[ -z "$POLICY" ]]; then
    echo "    policy ja estava desanexada da $DIST_ID."
  else
    echo "    removendo a policy $POLICY da distribuicao $DIST_ID"
    # Tem que ser string vazia explicita. Omitir o campo (del) nao funciona: a
    # API ignora a ausencia e preserva a associacao - testado, o update e aceito
    # com 200 e a policy continua la.
    jq '.DistributionConfig | .ContinuousDeploymentPolicyId = ""' "$TMP/get.json" > "$TMP/config.json"
    aws cloudfront update-distribution \
      --id "$DIST_ID" \
      --distribution-config "file://$TMP/config.json" \
      --if-match "$ETAG" \
      --output text --query 'Distribution.Id' > /dev/null
    echo "    desanexada."
  fi
fi

echo
echo "==> passo 2/2: destruindo o site"
terraform destroy -var 'attach_continuous_deployment_policy=false' "$@"
