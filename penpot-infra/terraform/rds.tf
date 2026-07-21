#Base de données postgres

# déclaration subnet group pour RDS
#RDS oblige de créer ce groupe qui regroupe les 2 réseaux privée pour positionner la BDD
# De plus RDS oblige de spécifier 2 réseaux dans 2 AZ différent. du fait que private network 1 = az 1
# private network 2 = AZ 2



resource "aws_db_subnet_group" "penpot" {
  name       = "${var.cluster_name}-db-subnet"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags       = local.tags
}

resource "aws_db_instance" "preprod" {
  identifier        = "${var.cluster_name}-preprod"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_encrypted = true
 
  db_name  = "penpot"
  username = "penpot"
  password = random_password.db_password.result
 
  db_subnet_group_name   = aws_db_subnet_group.penpot.name
  vpc_security_group_ids = [aws_security_group.rds.id]
 
  backup_retention_period   = 1
  skip_final_snapshot       = true
  tags                      = local.tags
  timeouts {
    delete = "40m"
  }

  depends_on = [random_password.db_password]
}

resource "aws_db_instance" "prod" {
  identifier        = "${var.cluster_name}-prod"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_encrypted = true
 
  db_name  = "penpot"
  username = "penpot"
  password = random_password.db_password.result
 
  db_subnet_group_name   = aws_db_subnet_group.penpot.name
  vpc_security_group_ids = [aws_security_group.rds.id]
 
  backup_retention_period   = 1
  skip_final_snapshot       = true
  tags                      = local.tags
  timeouts {
    delete = "40m"
  }

  depends_on = [random_password.db_password]
}