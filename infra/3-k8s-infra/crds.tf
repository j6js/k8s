# crds.tf : Install CRDs for whole cluster
# The CRDs Installed are:
# - coreos.com / Prometheus & Grafana etc
# - Gateway API
# - Envoy Gateway API
# These are all installed before any other
# resources. ArgoCD has a hissy fit during 
# bootstrap if the CRDs aren't present, 
# as well as any kubernetes_manifest 
# resources that depend on them etc.
locals {
    gateway_api_version = "1.5.1"
    gateway_api_url     = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v${local.gateway_api_version}/experimental-install.yaml"
    gateway_api_manifest = provider::kubernetes::manifest_decode_multi(data.http.gateway_api_raw.body)
}

data "http" "gateway_api_raw" {
  url = local.gateway_api_url
}

resource "helm_release" "o11y_crds" {
    name    = "prometheus-operator-crds"
    chart   = "oci://ghcr.io/prometheus-community/charts/prometheus-operator-crds"
    version = "29.0.0"
}

resource "kubernetes_manifest" "gateway_api_crds" {
    for_each = { for item in local.gateway_api_manifest : item.metadata.name => item }
    manifest = each.value
}

resource "helm_release" "envoy_gateway_crds" {
    name    = "envoy-gateway-crds"
    chart   = "oci://docker.io/envoyproxy/gateway-crds-helm"
    version = "v0.0.0-latest" # interesting versioning scheme
    values = {
        crds = {
            envoyGateway = {
                enabled = true
            }
            gatewayApi = {
                enabled = false # we do this ourselves, see line 5-9 and 21-24
            }
        }
    }
}
resource "null_resource" "wait_for_crds" {
    depends_on = [helm_release.o11y_crds, kubernetes_manifest.gateway_api_crds, helm_release.envoy_gateway_crds]
}