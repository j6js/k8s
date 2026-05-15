resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  chart      = "oci://quay.io/cilium/charts/cilium"
  version    = "1.19.4"

  set = [
    {
      name  = "ipam.mode"
      value = "kubernetes"
    },
    {
      name  = "kubeProxyReplacement"
      value = "true"
    },
    {
      name  = "k8sServiceHost"
      value = "localhost"
    },
    {
      name  = "k8sServicePort"
      value = "7445"
    },
    {
      name = "securityContext.capabilities.ciliumAgent"
      value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
    },
    { 
      name = "securityContext.capabilities.cleanCiliumState"
      value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
    },
    {
      name = "cgroup.autoMount.enabled"
      value = "false"
    },
    {
      name = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
    }
  ]
}