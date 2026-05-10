locals {
    vault_kms_input = jsondecode(file("${path.module}/config/outputs/1-oci-tf.json")).vault_kms
}

resource "kubernetes_secret" "vault_oci_kms" {
  metadata {
    name      = "vault-oci-kms"
    namespace = "vault"
  }
  data = vault_kms_input
}