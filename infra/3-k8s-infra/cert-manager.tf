# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_secret_v1" "cert_manager_cf_api" {
  metadata {
    name      = "cert-manager-cf-api"
    namespace = "cert-manager"
  }
  data = {
    api-token = data.sops_file.cloudflare.data["apiToken"]
  }
  depends_on = [
    kubernetes_namespace_v1.cert_manager
  ]
}
