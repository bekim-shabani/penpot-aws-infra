
# ============================================================
# ConfigMap preprod
# ============================================================
 
resource "kubernetes_config_map" "penpot_preprod" {
  metadata {
    name      = "penpot-config"
    namespace = "preprod"
  }
 
  data = {
    PENPOT_FLAGS                               = "disable-email-verification enable-smtp enable-prepl-server disable-secure-session-cookies enable-mcp"
    PENPOT_PUBLIC_URI                          = "https://preprod.${var.domain_name}"
    PENPOT_HTTP_SERVER_MAX_BODY_SIZE           = "367001600"
    PENPOT_HTTP_SERVER_MAX_MULTIPART_BODY_SIZE = "367001600"
 
    # Database preprod
    PENPOT_DATABASE_URI      = "postgresql://${aws_db_instance.preprod.endpoint}/penpot"
    PENPOT_DATABASE_USERNAME = "penpot"
 
    # Redis
    PENPOT_REDIS_URI = "redis://${aws_elasticache_cluster.penpot.cache_nodes[0].address}:6379/0"
 
    # Storage
    PENPOT_OBJECTS_STORAGE_BACKEND           = "fs"
    PENPOT_OBJECTS_STORAGE_FS_DIRECTORY      = "/opt/data/assets"
 
    # Telemetry
    PENPOT_TELEMETRY_ENABLED = "true"
    PENPOT_TELEMETRY_REFERER = "kubernetes"
 
    # SMTP — mailcatch preprod
    PENPOT_SMTP_DEFAULT_FROM     = "no-reply@example.com"
    PENPOT_SMTP_DEFAULT_REPLY_TO = "no-reply@example.com"
    PENPOT_SMTP_HOST             = "penpot-mailcatch"
    PENPOT_SMTP_PORT             = "1025"
    PENPOT_SMTP_TLS              = "false"
    PENPOT_SMTP_SSL              = "false"
 
    # Pool de connexions — réduit pour db.t3.micro
    PENPOT_DATABASE_MIN_POOL_SIZE = "5"
    PENPOT_DATABASE_MAX_POOL_SIZE = "20"
 
    # URIs internes nginx
    PENPOT_BACKEND_URI  = "http://penpot-backend:6060"
    PENPOT_EXPORTER_URI = "http://penpot-exporter:6061"
    PENPOT_MCP_URI      = "http://penpot-mcp:4401"
    PENPOT_MCP_URI_WS   = "http://penpot-mcp:4402"
  }
 
  depends_on = [
    kubernetes_namespace.preprod,
    aws_db_instance.preprod,
    aws_elasticache_cluster.penpot
  ]
}
 
# ============================================================
# ConfigMap prod
# ============================================================
 
resource "kubernetes_config_map" "penpot_prod" {
  metadata {
    name      = "penpot-config"
    namespace = "prod"
  }
 
  data = {
    PENPOT_FLAGS                               = "enable-email-verification enable-smtp enable-prepl-server enable-secure-session-cookies enable-mcp"
    PENPOT_PUBLIC_URI                          = "https://${var.domain_name}"
    PENPOT_HTTP_SERVER_MAX_BODY_SIZE           = "367001600"
    PENPOT_HTTP_SERVER_MAX_MULTIPART_BODY_SIZE = "367001600"
 
    # Database prod
    PENPOT_DATABASE_URI      = "postgresql://${aws_db_instance.prod.endpoint}/penpot"
    PENPOT_DATABASE_USERNAME = "penpot"
 
    # Redis
    PENPOT_REDIS_URI = "redis://${aws_elasticache_cluster.penpot.cache_nodes[0].address}:6379/1"
 
    # Storage
    PENPOT_OBJECTS_STORAGE_BACKEND           = "fs"
    PENPOT_OBJECTS_STORAGE_FS_DIRECTORY      = "/opt/data/assets"
 
    # Telemetry
    PENPOT_TELEMETRY_ENABLED = "true"
    PENPOT_TELEMETRY_REFERER = "kubernetes"
 
    # SMTP prod — remplacer par un vrai provider
    PENPOT_SMTP_DEFAULT_FROM     = var.smtp_email
    PENPOT_SMTP_DEFAULT_REPLY_TO = var.smtp_email
    PENPOT_SMTP_HOST             = "smtp.gmail.com"
    PENPOT_SMTP_PORT             = "587"
    PENPOT_SMTP_TLS              = "true"
    PENPOT_SMTP_SSL              = "false"
 
    # Pool de connexions — réduit pour db.t3.micro
    PENPOT_DATABASE_MIN_POOL_SIZE = "5"
    PENPOT_DATABASE_MAX_POOL_SIZE = "20"
 
    # URIs internes nginx
    PENPOT_BACKEND_URI  = "http://penpot-backend:6060"
    PENPOT_EXPORTER_URI = "http://penpot-exporter:6061"
    PENPOT_MCP_URI      = "http://penpot-mcp:4401"
    PENPOT_MCP_URI_WS   = "http://penpot-mcp:4402"
  }
 
  depends_on = [
    kubernetes_namespace.prod,
    aws_db_instance.prod,
    aws_elasticache_cluster.penpot
  ]
}