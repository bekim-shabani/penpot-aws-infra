# IAM Role pour backup des bases de données vers S3

# Policy document pour définir les autorisation sur le bucket écriture du json
data "aws_iam_policy_document" "backup_bdd_to_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",        # Upload
      "s3:GetObject",        # Téléchargement
      "s3:ListBucket",       
      "s3:DeleteObject"      
    ]
    resources = [
      aws_s3_bucket.bucket_penpot.arn,           
      "${aws_s3_bucket.bucket_penpot.arn}/*"     
    ]
  }
}

# IAM role qui sera rattaché à l'instance EC2 défini qui peut utiliser ce rôle
resource "aws_iam_role" "backup_s3_iam_role" {
  name = var.backup_role_bdd

  assume_role_policy = jsonencode({
    Version = "2012-10-17"  
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = var.backup_role_bdd
    Environment = var.environment
    Project     = var.project_name
  }
}

# création de l'iam policy
resource "aws_iam_policy" "backup_s3_policy" {
  name        = "penpot-backup-s3-policy"
  description = "Autorise les backups des BDD vers S3"
  policy      = data.aws_iam_policy_document.backup_bdd_to_s3.json

  tags = {
    Name        = "penpot-backup-s3-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attache la policy au role
resource "aws_iam_role_policy_attachment" "backup_policy_attachment" {
  role       = aws_iam_role.backup_s3_iam_role.name
  policy_arn = aws_iam_policy.backup_s3_policy.arn

}

# création de l'instance profile via l'iam role policy attachement
resource "aws_iam_instance_profile" "backup_profile" {
  name = "penpot-backup-profile"
  role = aws_iam_role.backup_s3_iam_role.name

  tags = {
    Name        = "penpot-backup-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}


# ============================================================
# IAM — Rôle du cluster EKS
# ============================================================
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ============================================================
# IAM — Rôle des nodes
# ============================================================
resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "eks_ebs_scsi_driver" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ============================================================
# IAM — Rôle EBS
# ============================================================

# Data source pour récupérer le thumbprint OIDC
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

# OIDC Provider
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  tags            = local.tags
}

# IAM Role pour EBS CSI Driver
resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.tags
}

# Attacher la policy AWS managée EBS CSI
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Addon EBS CSI Driver
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  tags                     = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi,
    aws_iam_openid_connect_provider.eks
  ]
}

# ============================================================
# iam.tf — User IAM pour GitLab CI
# ============================================================

resource "aws_iam_user" "gitlab_ci" {
  name = "${var.cluster_name}-gitlab-ci"
  tags = local.tags
}

resource "aws_iam_access_key" "gitlab_ci" {
  user = aws_iam_user.gitlab_ci.name
}

resource "aws_iam_user_policy" "gitlab_ci_eks" {
  name = "${var.cluster_name}-gitlab-ci-policy"
  user = aws_iam_user.gitlab_ci.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:*"]
      Resource = aws_eks_cluster.eks_cluster.arn
    }]
  })
}

resource "aws_eks_access_entry" "gitlab_ci" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_iam_user.gitlab_ci.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "gitlab_ci" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_iam_user.gitlab_ci.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope  { type = "cluster" }
}

# ============================================================
# alb_controller_iam.tf — IAM IRSA pour AWS Load Balancer Controller
# ============================================================

# ── IAM Policy pour ALB Controller ──────────────────────────

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:*", "elasticloadbalancing:*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:CreateServiceLinkedRole"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "wafv2:*",
          "waf-regional:*",
          "shield:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

# ── IAM Role IRSA ────────────────────────────────────────────

resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}