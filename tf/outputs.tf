output "vault_oci_kms_secret_yaml" {
  description = "SOPS-ready Kubernetes Secret manifest for Vault OCI KMS auto-unseal."
  value       = module.kms_for_hc_vault.vault_oci_kms_secret_yaml
  sensitive   = true
}

output "vault_oci_kms_key_id" {
  description = "OCI KMS key OCID used by Vault auto-unseal."
  value       = module.kms_for_hc_vault.key_id
}

output "vault_oci_kms_crypto_endpoint" {
  description = "OCI KMS crypto endpoint used by Vault auto-unseal."
  value       = module.kms_for_hc_vault.crypto_endpoint
}

output "vault_oci_kms_management_endpoint" {
  description = "OCI KMS management endpoint used by Vault auto-unseal."
  value       = module.kms_for_hc_vault.management_endpoint
}

output "vault_oci_kms_service_user_id" {
  description = "OCI IAM service user OCID used by Vault auto-unseal."
  value       = module.kms_for_hc_vault.service_user_id
}

output "vault_oci_kms_api_key_fingerprint" {
  description = "Fingerprint of the API key uploaded for Vault auto-unseal."
  value       = module.kms_for_hc_vault.api_key_fingerprint
}
