terraform {
    required_providers {
      kubernetes = {
        source  = "hashicorp/kubernetes"
        version = "3.1.0"
      }
      helm = {
        source  = "hashicorp/helm"
        version = "3.1.1"
      }
      sops = {
        source  = "carlpett/sops"
        version = "1.4.1"
      }
      kubectl = {
        source  = "gavinbunney/kubectl"
        version = "1.19.0"
      }
    }
}

provider "kubernetes" {
  config_path = "${path.module}/config/outputs/kubeconfig"
}

provider "kubectl" {
  config_path = "${path.module}/config/outputs/kubeconfig"
}
provider "helm" {
  kubernetes = {
    config_path = "${path.module}/config/outputs/kubeconfig"
  }
}