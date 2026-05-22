# Allow reading CNPG credentials from KV v2
path "secret/data/cnpg/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/cnpg/*" {
  capabilities = ["read", "list"]
}

# Allow listing the secret mount
path "secret/metadata" {
  capabilities = ["list"]
}
