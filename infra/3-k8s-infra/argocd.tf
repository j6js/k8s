resource "kubernetes_namespace_v1" "argocd_system" {
    metadata {
        name = "argocd"
    }
}

resource "kubernetes_secret_v1" "argocd_gh_app_secret" {
    metadata {
        name = "github-app-secret"
        namespace = kubernetes_namespace_v1.argocd_system.metadata[0].name
        labels = {
            "argocd.argoproj.io/secret-type" = "repository"
        }
    }
    data = {
        "type" = "git"
        "url" = "${yamldecode(file("${path.module}/shared/config.yaml")).argocd.repoUrl}"
        "githubAppID" = data.sops_file.argocd.data["githubAppID"]
        "githubAppInstallationID" = data.sops_file.argocd.data["githubAppInstallationID"]
        "githubAppPrivateKey" = data.sops_file.argocd.data["githubAppPrivateKey"]
    }
}
resource "helm_release" "argocd" {
    name       = "argocd"
    repository = "oci://ghcr.io/argoproj/argo-helm"
    chart      = "argocd"
    namespace  = "kubernetes_namespace_v1.argocd_system.metadata[0].name"
    version    = "${yamldecode(file("${path.module}/shared/config.yaml")).versions.argocd}"
    depends_on = [kubernetes_namespace_v1.argocd_system, kubernetes_secret_v1.argocd_gh_app_secret]
}
resource "kubernetes_config_map_v1" "argocd_cm" {
    metadata {
        name = "argocd-cm"
        namespace = kubernetes_namespace_v1.argocd_system.metadata[0].name
        labels = {    
            "app.kubernetes.io/name"    = "argocd-cm"
            "app.kubernetes.io/part-of" = "argocd"
        }
    }
    data = {
        "url" = yamldecode(file("${path.module}/shared/config.yaml")).argocd.externalUrl
        "commit.author.name" = "ArgoCD Bot"
        "commit.author.email" = "argocd@hl.j6js.com"
    }
    depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd" {
    yaml_body = file("${path.module}/argocd.yaml")
    depends_on = [helm_release.argocd]
}
