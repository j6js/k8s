resource "tls_private_key" "vault_auto_unseal" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "oci_kms_vault" "hc_vault_oci_kms" {
  compartment_id = var.compartment_ocid
  display_name   = "HC Vault Auto-Unseal via OCI KMS"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "hc_vault_oci_kms_key" {
  compartment_id = var.compartment_ocid
  display_name   = "HC Vault OCI KMS Key"

  key_shape {
    algorithm = "AES" # AES-256
    length    = 32
  }

  management_endpoint = oci_kms_vault.hc_vault_oci_kms.management_endpoint
}

resource "oci_identity_user" "vault_auto_unseal" {
  compartment_id = var.tenancy_ocid
  description    = "Service user used by Vault pods for OCI KMS auto-unseal."
  email          = "example-oci-kms@example.com"
  name           = var.service_user_name
}

resource "oci_identity_user_capabilities_management" "vault_auto_unseal" {
  user_id                      = oci_identity_user.vault_auto_unseal.id
  can_use_api_keys             = true
  can_use_auth_tokens          = false
  can_use_console_password     = false
  can_use_customer_secret_keys = false
  can_use_smtp_credentials     = false
}

resource "oci_identity_group" "vault_auto_unseal" {
  compartment_id = var.tenancy_ocid
  description    = "Allows Vault to use its OCI KMS key for auto-unseal."
  name           = var.service_group_name
}

resource "oci_identity_user_group_membership" "vault_auto_unseal" {
  group_id = oci_identity_group.vault_auto_unseal.id
  user_id  = oci_identity_user.vault_auto_unseal.id
}

resource "oci_identity_api_key" "vault_auto_unseal" {
  key_value = tls_private_key.vault_auto_unseal.public_key_pem
  user_id   = oci_identity_user.vault_auto_unseal.id

  depends_on = [oci_identity_user_capabilities_management.vault_auto_unseal]
}

resource "oci_identity_policy" "vault_auto_unseal" {
  compartment_id = var.tenancy_ocid
  description    = "Allow Vault auto-unseal user to use its OCI KMS key."
  name           = "vault-auto-unseal-kms"

  statements = [
    "Allow group ${oci_identity_group.vault_auto_unseal.name} to use keys in compartment id ${var.compartment_ocid} where target.key.id = '${oci_kms_key.hc_vault_oci_kms_key.id}'",
  ]
}
