# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

resource "helm_release" "cilium" {
  name      = "cilium"
  namespace = "kube-system"
  chart     = "oci://quay.io/cilium/charts/cilium"
  version   = yamldecode(file("${path.module}/config/config.yaml")).versions.cilium
  values = ["${yamlencode({
    ipam = {
      mode = "kubernetes"
    },
    kubeProxyReplacement = "true",
    k8sServiceHost       = "localhost",
    k8sServicePort       = "7445",
    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"],
        cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
      }
    }
    cgroup = {
      autoMount = {
        enabled = false
      },
      hostRoot = "/sys/fs/cgroup"
    }
  })}"]
}