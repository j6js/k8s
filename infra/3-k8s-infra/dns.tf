locals {
    node_info = jsondecode(file("${path.module}/config/outputs/1-oci-tf.json")).nodes
    base_domain = yamldecode(file("${path.module}/config/dns.yaml")).baseDomain
}

resource "kubernetes_namespace_v1" "external_dns" {
    metadata {
        name = "external-dns"
    }
}

resource "helm_release" "external_dns" {
  name          = "external-dns"
  namespace     = "external-dns"
  repository    = "https://kubernetes-sigs.github.io/external-dns/"
  chart         = "external-dns"
  version       = "1.20.0"
  wait          = true
  wait_for_jobs = true
  values = [
    <<VALUES
provider:
  name: cloudflare
crd:
  create: true
env:
  - name: CF_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: cloudflare-api-token
        key: apiKey

domainFilters:
  - ${local.base_domain}

policy: sync

sources:
  - service
  - ingress
  - crd
VALUES
  ]
  depends_on = [kubernetes_namespace_v1.external_dns]
}

resource "kubernetes_secret_v1" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = "external-dns"
  }
  data = {
    apiKey = data.sops_file.cloudflare.data["apiToken"]
  }
}

resource "kubectl_manifest" "global_dns_endpoint" {
  for_each = { for n in local.node_info : n.name => n }
  yaml_body = yamlencode({
    apiVersion = "externaldns.k8s.io/v1alpha1"
    kind       = "DNSEndpoint"
    metadata = {
      name      = "dns-${each.key}"
      namespace = "external-dns"
    }
    spec = {
        endpoints = [
            {
                dnsName = "${each.key}.hl.${local.base_domain}"
                recordType = "A"
                targets = [each.value.public_ipv4]
            }
        ]
    }
  })
  depends_on = [helm_release.external_dns]
}