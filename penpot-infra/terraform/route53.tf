#les records Route 53 dépendent du data.aws_lb.controller qui lit l'ALB créé par le controller.
#Mais l'ALB est créé par le controller après que les ingress sont appliqués.
#C'est pour ça il faut que Terraform attend 2 minutes avant de lire l'ALB.
resource "time_sleep" "wait_for_alb" {
  create_duration = "120s"
  depends_on = [
    kubernetes_ingress_v1.preprod,
    kubernetes_ingress_v1.prod
  ]
}

data "aws_lb" "controller" {
  name = "${var.cluster_name}-alb"

  depends_on = [time_sleep.wait_for_alb]
}

# Zone DNS principale pour lacapsule-penpot.studio
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = merge(local.tags, { Name = "${var.cluster_name}-zone" })
  lifecycle {
    prevent_destroy = true
  }
}

# Enregistrement CNAME pour valider le certificat ACM
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.penpot.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Enregistrement DNS — lacapsule-penpot.studio pointe vers l'ALB
# preprod.mon-domaine.com → ALB
resource "aws_route53_record" "penpot-preprod" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "preprod.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.controller.dns_name
    zone_id                = data.aws_lb.controller.zone_id
    evaluate_target_health = true
  }
}
# mon-domaine.com → ALB
resource "aws_route53_record" "prod" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = data.aws_lb.controller.dns_name
    zone_id                = data.aws_lb.controller.zone_id
    evaluate_target_health = true
  }
}
# www.mon-domaine.com → ALB
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.controller.dns_name
    zone_id                = data.aws_lb.controller.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "storybook" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "storybook.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.controller.dns_name
    zone_id                = data.aws_lb.controller.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "mailcatcher" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "mailcatcher.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.controller.dns_name
    zone_id                = data.aws_lb.controller.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "grafana.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.controller.dns_name
    zone_id                = data.aws_lb.controller.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53domains_registered_domain" "main" {
  domain_name = var.domain_name

  name_server {
    name = aws_route53_zone.main.name_servers[0]
  }
  name_server {
    name = aws_route53_zone.main.name_servers[1]
  }
  name_server {
    name = aws_route53_zone.main.name_servers[2]
  }
  name_server {
    name = aws_route53_zone.main.name_servers[3]
  }

  depends_on = [aws_route53_zone.main]
}
