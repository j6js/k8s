# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

resource "kubernetes_namespace_v1" "argocd_system" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_secret_v1" "argocd_repo" {
  metadata {
    name      = "argocd-repo"
    namespace = kubernetes_namespace_v1.argocd_system.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type                    = "git"
    url                     = yamldecode(file("${path.module}/config/config.yaml")).argocd.repoUrl
    githubAppID             = data.sops_file.argocd.data["githubAppID"]
    githubAppInstallationID = data.sops_file.argocd.data["githubAppInstallationID"]
    githubAppPrivateKey     = data.sops_file.argocd.data["githubAppPrivateKey"]
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "oci://ghcr.io/argoproj/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd_system.metadata[0].name
  version    = "9.5.17"

  values = [
    yamlencode({
      configs = {
        cm = {
          url                                                      = yamldecode(file("${path.module}/config/config.yaml")).argocd.externalUrl
          "commit.author.name"                                     = "ArgoCD Bot"
          "commit.author.email"                                    = "argocd@hl.j6js.com"
          "resource.customizations.health.argoproj.io_Application" = <<-EOT
            hs = {}
            hs.status = "Progressing"
            hs.message = ""
            if obj.status ~= nil then
              if obj.status.health ~= nil then
                hs.status = obj.status.health.status
                if obj.status.health.message ~= nil then
                  hs.message = obj.status.health.message
                end
              end
            end
            return hs
          EOT
        }
        params = {
          "server.insecure" = true
        }
      },
      controller = {
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled  = true
            interval = "30s"
            additionalLabels = {
              "release" = "kube-prometheus-stack"
            }
          }
        },
      },
      server = {
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled  = true
            interval = "30s"
            additionalLabels = {
              "release" = "kube-prometheus-stack"
            }
          }
        }
      },
      repoServer = {
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled  = true
            interval = "30s"
            additionalLabels = {
              "release" = "kube-prometheus-stack"
            }
          }
        }
      },
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.argocd_system,
    kubernetes_secret_v1.argocd_repo,
  ]
}

resource "kubectl_manifest" "root_application" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-application"
      namespace = kubernetes_namespace_v1.argocd_system.metadata[0].name
    }
    spec = {
      project = "default"
      source = {
        repoURL        = yamldecode(file("${path.module}/config/config.yaml")).argocd.repoUrl
        targetRevision = "main"
        path           = "argocd"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace_v1.argocd_system.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  })

  depends_on = [
    helm_release.argocd,
  ]
}
