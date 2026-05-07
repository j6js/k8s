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

for bin in kubectl cilium helm; do
  command -v "${bin}" >/dev/null 2>&1 || {
    echo "missing required binary: ${bin}" >&2
    exit 1
  }
done

if [[ ! -f "${KUBECONFIG}" ]]; then
  echo "kubeconfig not found at ${KUBECONFIG}" >&2
  exit 1
fi

CILIUM_VERSION="1.20.0-pre.2"
K8S_SERVICE_HOST="localhost"
K8S_SERVICE_PORT="7445"

# Ensure Helm repo is added and up-to-date
helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1 || true
helm repo update cilium >/dev/null 2>&1 || true

# Install Cilium without kube-proxy, following Talos docs:
# https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium#without-kube-proxy
#
# Key points:
#   - kubeProxyReplacement=true  (Cilium replaces kube-proxy entirely)
#   - k8sServiceHost=localhost / k8sServicePort=7445  (KubePrism on each node)
#   - cgroup.autoMount.enabled=false + cgroup.hostRoot  (Talos pre-mounts cgroupv2/bpffs)
#   - SYS_MODULE dropped from capabilities  (Talos doesn't allow module loading from pods)

cilium_args=(
  --version "${CILIUM_VERSION}"
  --set "ipam.mode=kubernetes"
  --set "kubeProxyReplacement=true"
  --set "k8sServiceHost=${K8S_SERVICE_HOST}"
  --set "k8sServicePort=${K8S_SERVICE_PORT}"
  --set "gatewayAPI.enabled=true"
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  --set "cgroup.autoMount.enabled=false"
  --set "cgroup.hostRoot=/sys/fs/cgroup"
)

if KUBECONFIG="${KUBECONFIG}" kubectl -n kube-system get daemonset cilium >/dev/null 2>&1; then
  echo "Cilium already present; running upgrade"
  KUBECONFIG="${KUBECONFIG}" cilium upgrade "${cilium_args[@]}"
else
  echo "Installing Cilium (kube-proxy-free, Talos)"
  KUBECONFIG="${KUBECONFIG}" cilium install "${cilium_args[@]}"
fi

KUBECONFIG="${KUBECONFIG}" cilium status --wait
