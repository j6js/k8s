data "sops_file" "flux_operator" {
    source_file = "${path.module}/../.sops/flux-operator.yaml"
}
data "sops_file" "flux_sops"{
    source_file = "${path.module}/../.sops/flux-sops.yaml"
}