# Vault Configuration — Manual Setup Steps

Run these once against the cluster after Vault is deployed and unsealed.

```bash
export VAULT_ADDR=https://vault.j6js.com  # or internal: http://infra-vault-internal.vault.svc.cluster.local:8200
export VAULT_TOKEN=<your-root-token>
```

## 1. Enable KV v2 secrets engine

```bash
vault secrets enable -version=2 -path=secret kv
```

## 2. Enable Kubernetes auth

```bash
vault auth enable kubernetes
```

## 3. Configure Kubernetes auth

```bash
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443" \
  issuer="https://kubernetes.default.svc.cluster.local"
```

## 4. Create policies

```bash
vault policy write cnpg-reader - <<'EOF'
path "secret/data/cnpg/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/cnpg/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata" {
  capabilities = ["list"]
}
EOF

vault policy write external-secrets - <<'EOF'
path "secret/data/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
EOF
```

## 5. Create K8s auth roles

```bash
vault write auth/kubernetes/role/external-secrets \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=external-secrets \
  ttl=1h

vault write auth/kubernetes/role/cnpg-reader \
  bound_service_account_names="*" \
  bound_service_account_namespaces="*" \
  policies=cnpg-reader \
  ttl=1h
```

## 6. Store CNPG credentials

For each CNPG cluster:

```bash
vault kv put secret/cnpg/<cluster-name>/superuser \
  username=postgres \
  password=<generated-password>
```

## 7. Verify

```bash
vault read auth/kubernetes/role/external-secrets
vault read auth/kubernetes/role/cnpg-reader
vault policy read cnpg-reader
vault policy read external-secrets
```
