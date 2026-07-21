# Security Group Configuration
# update security grp
# group security bastion 

resource "aws_security_group" "allow_ssh" {
  name        = var.security_group_name_bastion
  description = "Autorise le SSH entrant"
  vpc_id      = local.vpc_id

  tags = {
    Name        = var.security_group_name_bastion
    Environment = var.environment
    Project     = var.project_name

  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_rule" {
  security_group_id = aws_security_group.allow_ssh.id

  cidr_ipv4   = var.ssh_allowed_cidr
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "ssh_runner_rule" {
  security_group_id = aws_security_group.allow_ssh.id

  cidr_ipv4   = var.ssh_allowed_cidr
  from_port   = 20100
  ip_protocol = "tcp"
  to_port     = 20100
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress" {
  security_group_id = aws_security_group.allow_ssh.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

#groupe security database postgres

resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Allow PostgreSQL from EKS"
  vpc_id      = local.vpc_id
 
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = local.tags
}


#groupe security database redis

resource "aws_security_group" "redis" {
  name        = "${var.cluster_name}-redis-sg"
  description = "Allow Redis from EKS"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = local.tags
}

#GS EC2 hors bastion new

resource "aws_security_group" "allow_ssh_bastion" {
  name        = var.security_group_name_ec2
  description = "Autorise le SSH entrant provenant du bastion"
  vpc_id      = local.vpc_id

  tags = {
    Name        = var.security_group_name_bastion
    Environment = var.environment
    Project     = var.project_name

  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_rule_bastion" {
  security_group_id = aws_security_group.allow_ssh_bastion.id

  cidr_ipv4   = var.ssh_allowed_ec2_cidr
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress" {
  security_group_id = aws_security_group.allow_ssh_bastion.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "grafana_to_prometheus" {
  security_group_id = aws_security_group.allow_ssh_bastion.id

  cidr_ipv4   = "10.0.2.0/24"
  from_port   = 9090
  to_port     = 9090
  ip_protocol = "tcp"

  description = "Autorise communication entre grafana et prometheus"
}

# SecurityGroup du LoadBalancer → Grafana:3000
data "aws_security_groups" "managed_sg_lb" {
  filter {
    name   = "tag:ingress.k8s.aws/resource"
    values = ["ManagedLBSecurityGroup"]
  }
}
resource "aws_vpc_security_group_ingress_rule" "grafana_from_alb_managed" {
  for_each = toset(data.aws_security_groups.managed_sg_lb.ids)
  security_group_id            = aws_security_group.allow_ssh_bastion.id
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value
  description                  = "EKS cluster SG vers Grafana"
}

# GS Cluster
resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = local.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.tags, {
    Name = "${var.cluster_name}-cluster-sg"
  })
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS managed nodes"
  vpc_id      = local.vpc_id
  # Nodes → internet (sorties libres)
  egress {
    description = "Nodes vers internet (sorties libres)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Nodes ↔ nodes (communication intra-cluster)
  ingress {
    description = "Nodes depuis nodes (communication intra-cluster)"
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  # Control plane → nodes (kubelet, metrics, etc.)
  ingress {
    description     = "Control plane vers nodes (kubelet, metrics, etc.)"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }
  ingress {
    description     = "Allow ALB to reach nodes on 8080"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  tags = merge(local.tags, {
    Name = "${var.cluster_name}-node-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

# Règles ingress pour scap le node exporter sur les pods
resource "aws_vpc_security_group_ingress_rule" "prometheus_scrape_node_exporter" {
  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id

  cidr_ipv4   = "10.0.2.0/24"
  from_port   = 9100
  to_port     = 9100
  ip_protocol = "tcp"

  description = "autorise prometheus a scrap sur le pour 9100"
}

resource "aws_vpc_security_group_ingress_rule" "prometheus_scrape_penpot_metrics" {
  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id

  cidr_ipv4   = "10.0.2.0/24"
  from_port   = 6060
  to_port     = 6060
  ip_protocol = "tcp"

  description = "Autoruse prometheus a scrap les pods sur le 6000"
}

resource "aws_vpc_security_group_ingress_rule" "prometheus_scrape_kube_state_metrics" {
  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id

  cidr_ipv4   = "10.0.2.0/24"
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  description = "Autorise prometheus a scraper kube-state-metrics sur le port 8080"
}

# Security Group ALB
# Autorise HTTPS (443) et HTTP (80) depuis internet
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group pour ALB Penpot"
  vpc_id      = aws_vpc.main.id

  tags        = merge(local.tags, { Name = "${var.cluster_name}-alb-sg" })
}

# Règle entrante HTTP port 80
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Règle entrante HTTPS port 443
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Règle sortante — ALB peut contacter les Worker Nodes
resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
