#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BOOTSTRAP_ENV_FILE="${BOOTSTRAP_ENV_FILE:-${ROOT_DIR}/bootstrap.env}"
KUBECONFIG="${KUBECONFIG:-${ROOT_DIR}/kubeconfig}"

if [[ -f "${BOOTSTRAP_ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${BOOTSTRAP_ENV_FILE}"
  set +a
fi

for bin in kubectl flux helm; do
  command -v "${bin}" >/dev/null 2>&1 || {
    echo "missing required binary: ${bin}" >&2
    exit 1
  }
done

if [[ ! -f "${KUBECONFIG}" ]]; then
  echo "kubeconfig not found at ${KUBECONFIG}" >&2
  exit 1
fi

flux_args=(
  --namespace flux-system
  --create-namespace
)

echo "Get encrypted secrets for GitHub App Auth via SOPS"

SOPS_CONTENTS="$(sops -d "${SCRIPT_DIR}/../.sops/github-app.yaml")"
GH_APP_ID="$(echo "${SOPS_CONTENTS}" | yq '.app-id')"
GH_APP_INSTALLATION_ID="$(echo "${SOPS_CONTENTS}" | yq '.app-installation-id')"
GH_APP_PRIVATE_KEY="$(echo "${SOPS_CONTENTS}" | yq '.app-private-key')"


if kubectl get secret githubapp -n flux-system > /dev/null 2>&1; then
  echo "Secret alreary exists, updating"
  KUBECONFIG="${KUBECONFIG}" kubectl delete secret githubapp -n flux-system
  echo "${SOPS_CONTENTS}" | KUBECONFIG="${KUBECONFIG}" kubectl apply -f -
else
  echo "Secret does not exist"
  echo "${SOPS_CONTENTS}" | KUBECONFIG="${KUBECONFIG}" kubectl apply -f -
fi

if KUBECONFIG="${KUBECONFIG}" helm status flux-operator  -n flux-system > /dev/null 2>&1; then
  echo "Flux Operator already present; running upgrade"
  KUBECONFIG="${KUBECONFIG}" helm upgrade flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator "${flux_args[@]}"
else
  echo "Installing Flux Operator"
  KUBECONFIG="${KUBECONFIG}" helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator "${flux_args[@]}"
fi


echo "Applying Flux Instance config"
KUBECONFIG="${KUBECONFIG}" kubectl apply -f ${SCRIPT_DIR}/../flux/instance.yaml

echo "Flux bootstrap complete"
