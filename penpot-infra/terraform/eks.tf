# ============================================================
# Cluster EKS
# ============================================================
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn
  vpc_config {
    subnet_ids              = aws_subnet.private_subnets[*].id
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  timeouts {
    delete = "30m"
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
  tags = local.tags
}

# ============================================================
# Node Group
# ============================================================
resource "aws_eks_node_group" "penpot_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "penpot_nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private_subnets[*].id
  instance_types = [var.node_instance_type]
  scaling_config {
    min_size     = var.node_min_size
    max_size     = var.node_max_size
    desired_size = var.node_desired_size
  }
  disk_size = 50
  # Mise à jour progressive sans downtime
  update_config {
    max_unavailable = 1
  }
  timeouts {
    delete = "30m"
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ebs_scsi_driver
  ]
  tags = local.tags
}

# ============================================================
# Données nécessaires au provider Kubernetes
# ============================================================
data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = aws_eks_cluster.eks_cluster.name
}

# ============================================================
# Namespaces Kubernetes
# ============================================================
resource "kubernetes_namespace" "preprod" {
  metadata {
    name   = "preprod"
    labels = { environment = "preprod" }
  }
  lifecycle {
    ignore_changes = [metadata]
  }
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.penpot_nodes]
}
resource "kubernetes_namespace" "prod" {
  metadata {
    name   = "prod"
    labels = { environment = "prod" }
  }
  lifecycle {
    ignore_changes = [metadata]
  }
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.penpot_nodes]
}
