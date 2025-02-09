path "secret/data/backend-api/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/backend-api/*" {
  capabilities = ["list"]
}

path "secret/backend-api*" {
  capabilities = ["list"]
}