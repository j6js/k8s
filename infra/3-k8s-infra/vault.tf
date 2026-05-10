locals {
    vault_kms_input = jsondecode(file("${path.module}/config/outputs/1-oci-tf.json")).vault_kms
}

resource "kubernetes_secret_v1" "vault_oci_kms" {
  metadata {
    name      = "vault-oci-kms"
    namespace = "vault"
  }
  data = local.vault_kms_input
  depends_on = [
kubernetes_namespace_v1.vault
  ]
}
resource "kubernetes_namespace_v1" "vault" {
    metadata {
        name = "vault"
    }
}