data "kubernetes_secret" "vault_keys" {
  metadata {
    name      = "vault-keys"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }
}

locals {
  root_token = try(nonsensitive(data.kubernetes_secret.vault_keys.data["root-token"]), "")
}

output "ui_host_local" {
  value = local.ui_host_local
}

output "ui_host_external" {
  value = local.ui_host_external
}

output "vault_root_token" {
  value = local.root_token
}
