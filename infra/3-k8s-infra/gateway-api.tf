data "http" "gateway_api_crds" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml"
}
locals {
  gwapi_raw_manifests = provider::kubernetes::manifest_decode_multi(data.http.gateway_api_crds.response_body)
  
  gwapi_manifests = [
    for m in local.gwapi_raw_manifests : {
      for k, v in m : k => v if k != "status"
    }
  ]
}
resource "kubernetes_manifest" "gateway_api_crds" {
  count = length(local.gwapi_manifests)
  manifest = local.gwapi_manifests[count.index]
}