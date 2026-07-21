# Base de données Redis
#meme chose que pour la bdd postgres 


resource "aws_elasticache_subnet_group" "penpot" {
  name       = "${var.cluster_name}-cache-subnet"
  subnet_ids = aws_subnet.private_subnets[*].id
  tags       = local.tags
}

resource "aws_elasticache_cluster" "penpot" {
  cluster_id           = var.cluster_name
  engine               = "redis"
  node_type            = var.elasticache_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.penpot.name
  security_group_ids   = [aws_security_group.redis.id]
  tags                 = local.tags
}