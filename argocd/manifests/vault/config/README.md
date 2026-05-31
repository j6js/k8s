# Vault Configuration — Manual Setup Steps

Run these once against the cluster after Vault is deployed and unsealed.

```bash
export VAULT_ADDR=https://vault.j6js.com  # or internal: http://infra-vault-internal.vault.svc.cluster.local:8200
export VAULT_TOKEN=<your-root-token>
```

## 1. Enable Kubernetes auth

```bash
vault auth enable kubernetes
```

## 2. Configure Kubernetes auth

Since Vault runs in the same cluster with `service_registration "kubernetes"`,
it auto-discovers the API server. Minimal config:

```bash
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443" \
  issuer="https://kubernetes.default.svc.cluster.local"
```

## 3. Enable the database secrets engine

```bash
vault secrets enable database
```

## 4. Create policies for External Secrets

> **Note:** The database `creds/` paths generate dynamic credentials, which is
> effectively a create operation. Policies need both `read` and `create`
> capabilities — `read` alone will result in a 403 permission denied.

```bash
vault policy write cnpg-superuser - <<'EOF'
path "database/creds/cnpg-superuser" {
  capabilities = ["read", "create"]
}
EOF

vault policy write cnpg-app - <<'EOF'
path "database/creds/cnpg-app" {
  capabilities = ["read", "create"]
}
EOF
```

## 5. Create K8s auth roles

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

## 6. Create database roles

These define the SQL statements Vault uses to create/revoke dynamic PostgreSQL
roles. The `cnpg-superuser` role creates a PG superuser and is used for CNPG's
`spec.superuserSecret`. The `cnpg-app` role creates a user with read/write access
to all tables in `public` — adjust the `GRANT` statements to match your needs.

```bash
vault write database/roles/cnpg-superuser \
  db_name=cnpg \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' SUPERUSER" \
  revocation_statements="DROP ROLE IF EXISTS \"{{name}}\"" \
  default_ttl=1h \
  max_ttl=24h

vault write database/roles/cnpg-app \
  db_name=cnpg \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";" \
  revocation_statements="DROP ROLE IF EXISTS \"{{name}}\"" \
  default_ttl=1h \
  max_ttl=24h
```

## 7. Bootstrap the CNPG cluster (chicken-and-egg)

The CNPG `Cluster` references `superuserSecret`, which External Secrets populates
from Vault's `database/creds/cnpg-superuser` — but Vault's database connection
(`database/config/cnpg`) needs a running PostgreSQL to connect to. To break this
cycle:

**Step A — Deploy CNPG without `superuserSecret`:**

Temporarily remove or comment out `spec.superuserSecret` from the CNPG Cluster
manifest and apply. CNPG will use its built-in auto-generated superuser secret
instead.

```bash
# Let the cluster come up, then retrieve the auto-generated superuser password:
kubectl get secret -n cnpg cnpg-superuser -o jsonpath='{.data.password}' | base64 -d
```

> The auto-generated secret is usually named `<cluster-name>-superuser` (check with
> `kubectl get secrets -n cnpg`). CNPG creates it when `superuserSecret` is not set.

**Step B — Configure the Vault database connection:**

```bash
vault write database/config/cnpg \
  plugin_name=postgresql-database-plugin \
  allowed_roles="cnpg-superuser,cnpg-app" \
  connection_url="postgresql://{{username}}:{{password}}@cnpg.cnpg.svc.cluster.local:5432/postgres?sslmode=require" \
  username="postgres" \
  password="<paste-cnpg-superuser-password-here>" \
  password_authentication=scram-sha-256
```

**Step C — Verify Vault can generate credentials:**

```bash
vault read database/creds/cnpg-superuser
vault read database/creds/cnpg-app
```

**Step D — Restore `superuserSecret` on the CNPG Cluster:**

Re-add `spec.superuserSecret.name: cnpg-superuser` to the CNPG Cluster manifest.
External Secrets will now populate it from Vault, and CNPG will rotate to using
the Vault-managed superuser.

## 8. Verify everything together

```bash
# ExternalSecret should be synced
kubectl get externalsecret -n cnpg cnpg-superuser

# CNPG cluster should be healthy
kubectl get cluster -n cnpg cnpg

# Verify Vault credential generation still works
vault read database/creds/cnpg-superuser
vault read database/creds/cnpg-app

# Verify database roles
vault read database/roles/cnpg-superuser
vault read database/roles/cnpg-app

# Verify policies
vault policy read cnpg-superuser
vault policy read cnpg-app
```

## 9. (Optional) Rotate root credentials

After confirming everything works, rotate the root password so Vault is the only
one that knows it:

```bash
vault write -f database/rotate-root/cnpg
```

---

## Authentik Setup

These steps configure Vault for Authentik's SSO deployment. Run after the CNPG
cluster is healthy and Vault's database engine is configured (steps 1–7 above).

### 1. Create the Authentik database in CNPG

Connect to the CNPG cluster and create the database + role:

```bash
# Get the CNPG superuser password from Vault
export VAULT_TOKEN=<your-root-token>
DB_PASS=$(vault read -field=password database/creds/cnpg-superuser)

# Connect via psql (port-forward or from a pod in the cluster)
PGPASSWORD="$DB_PASS" psql -h cnpg-rw.cnpg.svc.cluster.local -U postgres -d postgres -c "CREATE ROLE authentik WITH LOGIN PASSWORD 'temp-bootstrap-password';"
PGPASSWORD="$DB_PASS" psql -h cnpg-rw.cnpg.svc.cluster.local -U postgres -d postgres -c "CREATE DATABASE authentik OWNER authentik;"
```

> **Note:** The password set here is temporary — Vault will manage it via dynamic
> credentials after step 3 below.

### 2. Create Vault policy for Authentik

```bash
vault policy write authentik - <<'EOF'
path "secret/data/authentik/*" {
  capabilities = ["read"]
}
EOF
```

### 3. Create K8s auth role for Authentik

```bash
vault write auth/kubernetes/role/authentik \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=authentik \
  policies=authentik \
  ttl=1h
```

### 4. Add the `authentik` database role to Vault

This allows Vault to generate dynamic credentials for the Authentik database:

```bash
vault write database/roles/authentik \
  db_name=cnpg \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON DATABASE authentik TO \"{{name}}\"; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";" \
  revocation_statements="DROP ROLE IF EXISTS \"{{name}}\"" \
  default_ttl=1h \
  max_ttl=24h
```

Update the `allowed_roles` on the existing CNPG database config to include `authentik`:

```bash
vault write database/config/cnpg \
  plugin_name=postgresql-database-plugin \
  allowed_roles="cnpg-superuser,cnpg-app,authentik" \
  connection_url="postgresql://{{username}}:{{password}}@cnpg.cnpg.svc.cluster.local:5432/postgres?sslmode=require" \
  username="postgres" \
  password="<current-password>" \
  password_authentication=scram-sha-256
```

### 5. Store the Authentik secret key in Vault

Generate a secret key and store it:

```bash
# Generate a random secret key
AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')

# Store in Vault
vault kv put secret/authentik/config secret_key="$AUTHENTIK_SECRET_KEY"
```

### 6. Store the Authentik database password in Vault

```bash
# Generate a strong password for the authentik DB user
AUTHENTIK_DB_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')

# Store in Vault
vault kv put secret/authentik/db password="$AUTHENTIK_DB_PASSWORD"

# Update the actual PostgreSQL role password to match
DB_PASS=$(vault read -field=password database/creds/cnpg-superuser)
PGPASSWORD="$DB_PASS" psql -h cnpg-rw.cnpg.svc.cluster.local -U postgres -d postgres -c "ALTER ROLE authentik WITH PASSWORD '$AUTHENTIK_DB_PASSWORD';"
```

### 7. Verify everything

```bash
# Vault can generate dynamic credentials for authentik
vault read database/creds/authentik

# KV secrets are readable
vault kv get secret/authentik/config
vault kv get secret/authentik/db

# ExternalSecrets in the authentik namespace should sync
kubectl get externalsecret -n authentik

# Authentik pods should come up
kubectl get pods -n authentik
```

---

## n8n and Redis Setup

These manifests expect External Secrets to read three KV paths from the `secrets`
KV v2 mount:

- `secrets/n8n`
- `secrets/cnpg/role/n8n`
- `secrets/redis/shared`

Create the backing secrets:

```bash
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
N8N_DB_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')

vault kv put secrets/n8n \
  N8N_ENCRYPTION_KEY="$N8N_ENCRYPTION_KEY" \
  N8N_HOST="n8n.j6js.com" \
  N8N_PORT="5678" \
  N8N_PROTOCOL="http"

vault kv put secrets/cnpg/role/n8n \
  username="n8n" \
  password="$N8N_DB_PASSWORD"

vault kv put secrets/redis/shared \
  password="$REDIS_PASSWORD"
```

Allow the `vault-backend` ClusterSecretStore role to read those paths. When
updating the Kubernetes auth role, preserve any other policies already attached
to it:

```bash
vault policy write external-secrets-kv - <<'EOF'
path "secrets/data/n8n" {
  capabilities = ["read"]
}

path "secrets/data/cnpg/role/n8n" {
  capabilities = ["read"]
}

path "secrets/data/redis/shared" {
  capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/cnpg-superuser \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=<existing-policies>,external-secrets-kv \
  ttl=1h
```

Verify the generated Kubernetes secrets after Argo syncs:

```bash
kubectl get externalsecret -n cnpg cnpg-n8n
kubectl get externalsecret -n redis redis-auth
kubectl get externalsecret -n n8n n8n-generated n8n-db-secrets redis-auth
```
