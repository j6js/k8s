# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

resource "helm_release" "cilium" {
  name      = "cilium"
  namespace = "kube-system"
  chart     = "oci://quay.io/cilium/charts/cilium"
  version   = yamldecode(file("${path.module}/config/config.yaml")).versions.cilium
  values = ["${yamlencode({
    ipv4 = {
      enabled = true
    },
    ipv4NativeRoutingCIDR = "10.0.0.0/8",
    ipv6NativeRoutingCIDR = "fd00:10::/104"
    ipv6 = {
      enabled = true
    },
    ipam = {
      mode = "kubernetes"
    },
    prometheus = {
      enabled = true
      serviceMonitor = {
        enabled = true
      }
    },
    operator = {
      prometheus = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    },
    hubble = {
      enabled = true
      metrics = {
        enabled = ["dns","drop","tcp","flow","port-distribution","icmp","httpV2:exemplars=true;", "labelsContext=source_ip", "source_namespace", "source_workload", "destination_ip", "destination_namespace", "destination_workload", "traffic_direction"]
        serviceMonitor = {
          enabled = true
      }
      }
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