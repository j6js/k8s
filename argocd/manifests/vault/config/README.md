# Vault Configuration — Manual Setup Steps

Run these once against the cluster after Vault is deployed and unsealed.

```bash
export VAULT_ADDR=https://vault.j6js.com  # or internal: http://infra-vault-internal.vault.svc.cluster.local:8200
export VAULT_TOKEN=<your-root-token>
```

## 1. Enable the database secrets engine

```bash
vault secrets enable database
```

## 2. Configure the PostgreSQL connection

This connects Vault to your CNPG-managed PostgreSQL. Vault needs a privileged user
that can create/rotate roles. CNPG automatically creates a `postgres` superuser —
retrieve its password from the K8s secret that CNPG generates (e.g. `cnpg-cluster-app`
in the application namespace).

```bash
vault write database/config/cnpg \
  plugin_name=postgresql-database-plugin \
  allowed_roles="cnpg-superuser,cnpg-app" \
  connection_url="postgresql://{{username}}:{{password}}.<CNPG_CLUSTER_NAMESPACE>.svc.cluster.local:5432/postgres?sslmode=require" \
  username="postgres" \
  password="<cnpg-superuser-password>" \
  password_authentication=scram-sha-256
```

> **Note:** Replace `<CNPG_CLUSTER_NAMESPACE>` with the namespace where your CNPG
> Cluster runs, and `<cnpg-superuser-password>` with the password from the CNPG-managed
> K8s secret (usually named `<cluster-name>-superuser` or similar).

## 3. Create a superuser role (for CNPG `superuserSecret`)

This role creates a new PostgreSQL superuser with a 1h TTL. Used for CNPG's
`spec.superuserSecret`.

```bash
vault write database/roles/cnpg-superuser \
  db_name=cnpg \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' SUPERUSER" \
  revocation_statements="DROP ROLE IF EXISTS \"{{name}}\"" \
  default_ttl=1h \
  max_ttl=24h
```

## 4. Create an app role (for application connections)

This role creates a user with read/write access to all tables in `public`.
Adjust the `GRANT` statements to match your needs.

```bash
vault write database/roles/cnpg-app \
  db_name=cnpg \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";" \
  revocation_statements="DROP ROLE IF EXISTS \"{{name}}\"" \
  default_ttl=1h \
  max_ttl=24h
```

## 5. Create policies for External Secrets

```bash
vault policy write cnpg-superuser - <<'EOF'
path "database/creds/cnpg-superuser" {
  capabilities = ["read"]
}
EOF

vault policy write cnpg-app - <<'EOF'
path "database/creds/cnpg-app" {
  capabilities = ["read"]
}
EOF
```

## 6. Create K8s auth roles

```bash
vault write auth/kubernetes/role/cnpg-superuser \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=cnpg-superuser \
  ttl=1h

vault write auth/kubernetes/role/cnpg-app \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=cnpg-app \
  ttl=1h
```

## 7. Verify

```bash
# Test dynamic credential generation
vault read database/creds/cnpg-superuser
vault read database/creds/cnpg-app

# Verify roles
vault read database/roles/cnpg-superuser
vault read database/roles/cnpg-app

# Verify policies
vault policy read cnpg-superuser
vault policy read cnpg-app
```

## 8. (Optional) Rotate root credentials

After confirming everything works, rotate the root password so Vault is the only
one that knows it:

```bash
vault write -f database/rotate-root/cnpg
```
