output "vault_oci_kms_secret_yaml" {
  description = "SOPS-ready Kubernetes Secret manifest for Vault OCI KMS auto-unseal."
  value       = module.kms_for_hc_vault.vault_oci_kms_secret_yaml
  sensitive   = true
}
