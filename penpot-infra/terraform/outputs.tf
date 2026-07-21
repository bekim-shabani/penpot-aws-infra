# ============================================================
# outputs.tf
# ============================================================

output "cluster_name" {
  value = var.cluster_name
}

output "rds_endpoint_preprod" {
  value = aws_db_instance.preprod.endpoint
}

output "rds_endpoint_prod" {
  value = aws_db_instance.prod.endpoint
}

output "db_password" {
  description = "Mot de passe PostgreSQL RDS"
  value       = random_password.db_password.result
  sensitive   = true
}
output "elasticache_endpoint" {
  value = aws_elasticache_cluster.penpot.cache_nodes[0].address
}


output "gitlab_ci_access_key_id" {
  description = "AWS_ACCESS_KEY_ID pour GitLab CI/CD Variables"
  value       = aws_iam_access_key.gitlab_ci.id
}

output "gitlab_ci_secret_access_key" {
  description = "AWS_SECRET_ACCESS_KEY pour GitLab CI/CD Variables"
  value       = aws_iam_access_key.gitlab_ci.secret
  sensitive   = true
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}

output "route53_nameservers" {
  description = "Nameservers Route 53"
  value       = aws_route53_zone.main.name_servers
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "prometheus_private_ip" {
  value = aws_instance.prometheus.private_ip
}

output "grafana_private_ip" {
  value = aws_instance.grafana.private_ip
}