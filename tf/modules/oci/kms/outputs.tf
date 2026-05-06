locals {
  vault_oci_kms_secret = {
    "VAULT_OCIKMS_CRYPTO_ENDPOINT"     = oci_kms_vault.hc_vault_oci_kms.crypto_endpoint
    "VAULT_OCIKMS_MANAGEMENT_ENDPOINT" = oci_kms_vault.hc_vault_oci_kms.management_endpoint
    "VAULT_OCIKMS_SEAL_KEY_ID"         = oci_kms_key.hc_vault_oci_kms_key.id
    "OCI_REGION"                       = var.region
    "OCI_TENANCY_OCID"                 = var.tenancy_ocid
    "OCI_USER_OCID"                    = oci_identity_user.vault_auto_unseal.id
    "OCI_FINGERPRINT"                  = oci_identity_api_key.vault_auto_unseal.fingerprint
    "OCI_PRIVATE_KEY"                  = tls_private_key.vault_auto_unseal.private_key_pem
    "config" = templatefile("${path.module}/oci-config.tftpl", {
      tenancy_ocid = var.tenancy_ocid
      user_ocid    = oci_identity_user.vault_auto_unseal.id
      fingerprint  = oci_identity_api_key.vault_auto_unseal.fingerprint
      region       = var.region
      key_file     = "/vault/userconfig/vault-oci-kms/OCI_PRIVATE_KEY"
    })
  }
}

output "vault_id" {
  value = oci_kms_vault.hc_vault_oci_kms.id
}

output "key_id" {
  value = oci_kms_key.hc_vault_oci_kms_key.id
}

output "crypto_endpoint" {
  value = oci_kms_vault.hc_vault_oci_kms.crypto_endpoint
}

output "management_endpoint" {
  value = oci_kms_vault.hc_vault_oci_kms.management_endpoint
}

output "service_user_id" {
  value = oci_identity_user.vault_auto_unseal.id
}

output "api_key_fingerprint" {
  value = oci_identity_api_key.vault_auto_unseal.fingerprint
}

output "vault_oci_kms_secret" {
  value     = local.vault_oci_kms_secret
  sensitive = true
}

output "vault_oci_kms_secret_yaml" {
  value = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "vault-oci-kms"
      namespace = "vault"
    }
    type       = "Opaque"
    stringData = local.vault_oci_kms_secret
  })
  sensitive = true
}
