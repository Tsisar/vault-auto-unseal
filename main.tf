locals {
  ui_host_local = "vault.${var.domain_local}"
  ui_host_external = "vault.${var.domain_external}"
}

resource "helm_release" "vault" {
  name       = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "v0.29.1"

  values = [
    file("${path.module}/values.yaml")
  ]
}

resource "kubernetes_ingress_v1" "vault_lan" {
  metadata {
    name      = "vault-ingress-local"
    namespace = kubernetes_namespace.vault.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = local.ui_host_local
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "vault-ui"
              port {
                number = 8200
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "vault" {
  metadata {
    name      = "vault-ingress"
    namespace = "vault"
    labels = {
      "app.kubernetes.io/instance" = "vault"
    }
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "cert-manager.io/cluster-issuer"                 = "letsencrypt-issuer"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = local.ui_host_external
      http {
        path {
          backend {
            service {
              name = "vault-ui"
              port {
                number = 8200
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }

    tls {
      hosts = [local.ui_host_external]
      secret_name = "vault-tls-letsencrypt"
    }
  }
}
