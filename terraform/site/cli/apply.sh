#!/usr/bin/env bash
#
# Cria o modulo site em dois passos.
#
# Por que dois: a API do CloudFront recusa ContinuousDeploymentPolicyId no
# CreateDistribution ("Continuous deployment policy is not supported during
# distribution creation"). A policy so pode ser anexada por UpdateDistribution,
# ou seja, depois que a distribuicao primaria ja existe.
#
#   passo 1 - cria tudo, inclusive a policy, mas sem anexa-la.
#   passo 2 - anexa a policy na distribuicao primaria (UpdateDistribution).
#
# O passo 2 nao precisa esperar a distribuicao sair de InProgress: o CloudFront
# aceita o update na hora (medido: 2s). Por isso wait_for_deployment fica false.
#
# Uso: ./apply.sh [args extras do terraform, ex: -auto-approve]
#
set -euo pipefail

# O script vive em site/cli/, o modulo terraform e o diretorio acima.
cd "$(dirname "$0")/.."

echo "==> passo 1/2: criando o site sem a continuous deployment policy"
terraform apply -var 'attach_continuous_deployment_policy=false' "$@"

echo
echo "==> passo 2/2: anexando a continuous deployment policy"
terraform apply -var 'attach_continuous_deployment_policy=true' "$@"

echo
echo "==> site pronto, com a policy anexada."
echo "    para derrubar, use ./destroy.sh (um terraform destroy direto falha:"
echo "    a AWS recusa deletar a policy enquanto ela estiver anexada)."
