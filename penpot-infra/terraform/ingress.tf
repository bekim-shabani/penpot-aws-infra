# ── Ingress preprod ─────────────────────────────────────────

resource "kubernetes_ingress_v1" "preprod" {
  metadata {
    name      = "app-ingress"
    namespace = "preprod"

    annotations = {
      "kubernetes.io/ingress.class"                        = "alb"
      "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"              = "ip"
      "alb.ingress.kubernetes.io/listen-ports"             = jsonencode([{ HTTP  = 80  }, { HTTPS = 443 }])
      "alb.ingress.kubernetes.io/ssl-redirect"             = "443"
      "alb.ingress.kubernetes.io/certificate-arn"          = "${aws_acm_certificate_validation.penpot.certificate_arn}"
      "alb.ingress.kubernetes.io/group.name"               = "${var.cluster_name}"
      "alb.ingress.kubernetes.io/load-balancer-name"       = "${var.cluster_name}-alb"
      "alb.ingress.kubernetes.io/proxy-body-size"          = "350m"
    }
  }

  spec {
    # Frontend
    rule {
      host = "preprod.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "penpot-frontend"
              port {
                number = 9001
              }
            }
          }
        }
      }
    }

    # Storybook sur sous-domaine dédié
    rule {
      host = "storybook.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "penpot-storybook"
              port {
                number = 6006
              }
            }
          }
        }
      }
    }

    # Mailcatcher sur sous-domaine dédié
    rule {
      host = "mailcatcher.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "penpot-mailcatch"
              port {
                number = 1080
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.preprod,
    aws_acm_certificate_validation.penpot
  ]
}

# ── Ingress prod ────────────────────────────────────────────

resource "kubernetes_ingress_v1" "prod" {
  metadata {
    name      = "app-ingress"
    namespace = "prod"

    annotations = {
      "kubernetes.io/ingress.class"                        = "alb"
      "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"              = "ip"
      "alb.ingress.kubernetes.io/listen-ports"             = jsonencode([{ HTTP  = 80  }, { HTTPS = 443 }])
      "alb.ingress.kubernetes.io/ssl-redirect"             = "443"
      "alb.ingress.kubernetes.io/certificate-arn"          = "${aws_acm_certificate_validation.penpot.certificate_arn}"
      "alb.ingress.kubernetes.io/group.name"               = "${var.cluster_name}"
      "alb.ingress.kubernetes.io/load-balancer-name"       = "${var.cluster_name}-alb"
      "alb.ingress.kubernetes.io/proxy-body-size"          = "350m"
    }
  }

  spec {
    rule {
      host = var.domain_name

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "penpot-frontend"
              port {
                number = 9001
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.prod,
    aws_acm_certificate_validation.penpot
  ]
}