# Demande du certificat SSL pour lacapsule.penpot
resource "aws_acm_certificate" "penpot" {
  domain_name       = var.domain_name
  subject_alternative_names = [
      "*.${var.domain_name}"   # couvre preprod.mon-domaine.com et tout sous-domaine
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags, { Name = "${var.cluster_name}-cert" })
}

# Validation du certificat via les enregistrements DNS Route53
resource "aws_acm_certificate_validation" "penpot" {
  certificate_arn = aws_acm_certificate.penpot.arn

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]
}
