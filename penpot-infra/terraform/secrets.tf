# ============================================================
# secrets.tf — Génération et injection des secrets Kubernetes
# ============================================================

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "penpot_secret_key" {
  length  = 64
  special = false
}

resource "kubernetes_secret" "app_secrets_preprod" {
  metadata {
    name      = "app-secrets"
    namespace = "preprod"
  }

  data = {
    POSTGRES_PASSWORD = random_password.db_password.result
    PENPOT_SECRET_KEY = random_password.penpot_secret_key.result
  }

  depends_on = [kubernetes_namespace.preprod]
}

resource "kubernetes_secret" "app_secrets_prod" {
  metadata {
    name      = "app-secrets"
    namespace = "prod"
  }

  data = {
    POSTGRES_PASSWORD = random_password.db_password.result
    PENPOT_SECRET_KEY = random_password.penpot_secret_key.result
  }

  depends_on = [kubernetes_namespace.prod]
}

resource "kubernetes_secret" "registry_preprod" {
  metadata {
    name      = "registry-secret"
    namespace = "preprod"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.gitlab.com" = {
          username = var.gitlab_registry_user
          password = var.gitlab_registry_token
          auth     = base64encode("${var.gitlab_registry_user}:${var.gitlab_registry_token}")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace.preprod]
}

resource "kubernetes_secret" "registry_prod" {
  metadata {
    name      = "registry-secret"
    namespace = "prod"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.gitlab.com" = {
          username = var.gitlab_registry_user
          password = var.gitlab_registry_token
          auth     = base64encode("${var.gitlab_registry_user}:${var.gitlab_registry_token}")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace.prod]
}

resource "kubernetes_secret" "smtp_prod" {
   metadata {
     name      = "smtp-secret"
     namespace = "prod"
   }

   data = {
     PENPOT_SMTP_USERNAME = var.smtp_email
     PENPOT_SMTP_PASSWORD = var.smtp_password
   }
 }
