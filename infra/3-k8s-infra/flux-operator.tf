resource "kubernetes_namespace_v1" "flux_system" {
    metadata {
        name = "flux-system"
    }
}

resource "kubernetes_secret_v1" "flux_sops_secret" {
    metadata {
        name = "sops-age"
        namespace = kubernetes_namespace_v1.flux_system.metadata[0].name
    }
    data = {
        "age.agekey" = data.sops_file.flux_sops.data["value"]
    }
}
resource "kubernetes_secret_v1" "flux_operator_secret" {
    metadata {
        name = "github-sa"
        namespace = kubernetes_namespace_v1.flux_system.metadata[0].name
    }
    data = {
        "githubAppID" = data.sops_file.flux_operator.data["githubAppID"]
        "githubAppInstallationID" = data.sops_file.flux_operator.data["githubAppInstallationID"]
        "githubAppPrivateKey" = data.sops_file.flux_operator.data["githubAppPrivateKey"]
    }
}
resource "helm_release" "flux_operator" {
    name       = "flux-operator"
    repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
    chart      = "flux-operator"
    namespace  = "flux-system"
    version    = "0.48.0"
    depends_on = [
        kubernetes_namespace_v1.flux_system,
        kubernetes_secret_v1.flux_sops_secret,
        kubernetes_secret_v1.flux_operator_secret
    ]
}

resource "kubectl_manifest" "flux_operator" {
    yaml_body = file("${path.module}/flux-operator.yaml")
    depends_on = [helm_release.flux_operator]
}
