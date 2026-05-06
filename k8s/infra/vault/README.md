# Vault OCI KMS Auto-Unseal

Vault is configured to use OCI KMS with API key authentication. Terraform owns the OCI KMS vault, key, service user, group, API key upload, and key-use policy. Flux owns the Kubernetes Secret that passes those values to the Vault Helm chart.

## Workflow

1. Apply Terraform from `tf/`.
2. Export the generated Kubernetes Secret manifest:

   ```sh
   terraform -chdir=tf output -raw vault_oci_kms_secret_yaml
   ```

3. Encrypt that output into `k8s/infra/vault/oci-kms.secret.yaml` with SOPS. Use this filename so `.sops.yaml` selects the Flux age recipient:

   ```sh
   terraform -chdir=tf output -raw vault_oci_kms_secret_yaml | sops --encrypt --filename-override k8s/infra/vault/oci-kms.secret.yaml /dev/stdin > k8s/infra/vault/oci-kms.secret.yaml
   ```

4. Commit only the SOPS-encrypted secret.

## Notes

- The generated OCI private API key is stored in Terraform state because Terraform creates the key pair. Keep `tf/terraform.tfstate` local and out of git.
- The Vault Helm chart reads secret-backed environment variables through `server.extraSecretEnvironmentVars`.
- Vault's OCI seal expects the `VAULT_OCIKMS_*` environment variable names, not `VAULT_OCI_KMS_*`.
