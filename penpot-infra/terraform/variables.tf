
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-north-1"
}


variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "penpot"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

#AZ

variable "availability_zones" {
  type        = list(string)
  description = "Availability Zones for subnets"
  default     = ["eu-north-1a", "eu-north-1b"]
}

# EC2 Instance Configuration
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-01ef747f983799d6f"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_names" {
  description = "Noms des instances EC2"
  type        = map(string)
  default = {
    bastion     = "penpot-bastion"
    grafana     = "penpot-grafana"
    prometheus  = "penpot-prometheus"
    master_node = "penpot-master_node"
    worker_1    = "penpot-worker_1"
    worker_2    = "penpot-worker_2"
  }
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "securem"
}

# Security Group Configuration bastion
variable "security_group_name_bastion" {
  description = "Name of the security group"
  type        = string
  default     = "penpot-allow-ssh"
}

variable "ssh_allowed_cidr" {
  description = "CIDR autorisé en SSH sur le bastion (ports 22 et 20100). À restreindre à l'IP d'administration — ne jamais laisser 0.0.0.0/0 en production."
  type        = string
  # Pas de valeur par défaut volontairement : la valeur doit être fournie explicitement
  # (via tfvars ou -var) pour éviter d'exposer le SSH à tout Internet.
}


# Security Group Configuration database postgres
variable "postgres_allowed_cidr" {
  description = "CIDR block allowed to connect to PostgreSQL"
  type        = string
  default     = "10.0.2.0/24"
}

# Security Group Configuration database redis
variable "redis_allowed_cidr" {
  description = "CIDR block allowed to connect to redis"
  type        = string
  default     = "10.0.2.0/24"
}

# Security group configuration pour les EC2 hors bastion

variable "security_group_name_ec2" {
  description = "SG autorise ssh via bastion"
  type        = string
  default     = "penpot-allow-ssh-from-bastion"
}

variable "ssh_allowed_ec2_cidr" {
  description = "CIDR autorisé en SSH sur les instances privées — restreint au sous-réseau public, donc au bastion"
  type        = string
  default     = "10.0.1.0/24"
}



#Subnets

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  # Ajout d'un second subnet public en eu-north-1b requis par l'ALB (minimum 2 AZ)
  default = ["10.0.1.0/24", "10.0.4.0/24"]
}


variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}


#IAM

variable "backup_role_bdd" {
  description = "role Iam permettant de faire les backup de bdd vers S3"
  type        = string
  default     = "IAM-BDD-BACKUP-S3"
}

variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
  default     = "penpotproject"
}

variable "cluster_version" {
  description = "Version Kubernetes"
  type        = string
  default     = "1.36"
}

variable "node_instance_type" {
  description = "Type instance worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "db_instance_class" {
  description = "Classe instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "elasticache_node_type" {
  description = "Type noeud ElastiCache"
  type        = string
  default     = "cache.t3.micro"
}

variable "gitlab_registry_user" {
  description = "Utilisateur GitLab Registry (ex: gitlab-ci-token)"
  type        = string
  default     = ""
}

variable "gitlab_registry_token" {
  description = "Token GitLab Registry (CI_REGISTRY_PASSWORD)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "domain_name" {
  description = "Nom de domaine"
  type        = string
  default     = "lacapsule-penpot.studio"
}


variable "smtp_email" {
  description = "Email proprietaire du compte ayant généré le App Password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "smtp_password" {
  description = "Mot de passe SMTP Google App Password"
  type        = string
  sensitive   = true
  default     = ""
}