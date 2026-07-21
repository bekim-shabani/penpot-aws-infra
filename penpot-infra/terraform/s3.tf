#bucket S3 pour backup bdd
resource "aws_s3_bucket" "bucket_penpot" {
    bucket = "penpot-backup"

    tags = {
      Name        = "penpot-backup"
      Environment = var.environment
      Project     = var.project_name
    }
}

#Versioning bucket s3 garde l'historique des modification de fichier
resource "aws_s3_bucket_versioning" "penpot_versioning" {
    bucket = aws_s3_bucket.bucket_penpot.id

    versioning_configuration {
    status = "Enabled"
    }
}

# Retention et traitement des ressources
resource "aws_s3_bucket_lifecycle_configuration" "bucket_penpot" {
  bucket = aws_s3_bucket.bucket_penpot.id

  # Règle pour backups postgres preprod
  rule {
    id     = "postgres-backups-preprod"
    status = "Enabled"
    filter {
      prefix = "preprod/"
    }
    expiration {
      days = 7
    }
  }

  # Règle pour backups postgres prod
  rule {
    id     = "postgres-backups-prod"
    status = "Enabled"
    filter {
      prefix = "prod/"
    }
    expiration {
      days = 7
    }
  }
}

#Encryption des données
resource "aws_s3_bucket_server_side_encryption_configuration" "penpot_encryption" {
  bucket = aws_s3_bucket.bucket_penpot.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

#bloc de sécurité pour bloquer l'accès public sans authentification
resource "aws_s3_bucket_public_access_block" "bucket_penpot" {
  bucket = aws_s3_bucket.bucket_penpot.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}