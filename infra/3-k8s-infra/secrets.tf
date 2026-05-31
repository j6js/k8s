
data "sops_file" "argocd" {
  source_file = "${path.module}/../.sops/argocd.yaml"
}
data "sops_file" "cloudflare" {
  source_file = "${path.module}/../.sops/cloudflare.yaml"
}