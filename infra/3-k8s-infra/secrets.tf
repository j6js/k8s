# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

data "sops_file" "argocd" {
  source_file = "${path.module}/../.sops/argocd.yaml"
}
data "sops_file" "cloudflare" {
  source_file = "${path.module}/../.sops/cloudflare.yaml"
}