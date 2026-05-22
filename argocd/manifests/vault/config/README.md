# Vault Configuration

This directory contains manifests that configure Vault after it's deployed.
Applied at ArgoCD sync-wave 1 (same wave as the Vault Helm release).

## One-time setup required

Before the `vault-config` Job can run, you must create a secret containing
the Vault root token:

```bash
kubectl create secret generic vault-root-token \
  --namespace vault \
  --from-literal=root-token=<your-vault-root-token>
```

The root token is generated during `vault operator init`. If you used the
Helm chart with OCI KMS auto-unseal, the init happens automatically and
the root token was printed to the pod logs of the first Vault pod.

To retrieve it from the Vault pod:

```bash
kubectl logs -n vault infra-vault-0 | grep "Root Token"
```

## What the Job configures

1. **KV v2 secrets engine** at `secret/`
2. **Kubernetes auth method** with token reviewer
3. **Policy `cnpg-reader`** — read-only access to `secret/data/cnpg/*`
4. **Policy `external-secrets`** — read-only access to `secret/data/*`
5. **K8s auth role `external-secrets`** — for the `external-secrets` SA in the `external-secrets` namespace
6. **K8s auth role `cnpg-reader`** — for any SA in any namespace (restricted by policy)
