###################### RDS Database
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster

#https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-mysql-parallel-query.html
data "aws_availability_zones" "available" {}

resource "aws_cloudwatch_log_group" "database" {
  name = "db-${var.name}-${var.env}"

  tags = {
    Environment = var.env
    Application = "${var.name}-${var.env}"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.name}-${var.env}"
  subnet_ids = tolist(var.private_subnets)

  tags = {
    Name        = "${var.name} subnet group ${var.env}"
    Environment = var.env
    Application = "db-${var.name}-${var.env}"
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rdsCredentials" {
  name = "rdsCredentials"
}



resource "aws_rds_cluster" "default" {
  cluster_identifier   = "rds-aurora-${var.env}"
  db_subnet_group_name = aws_db_subnet_group.default.name
  engine               = "aurora-mysql"
  engine_version       = "5.7.mysql_aurora.2.03.2"
  # allocated_storage         = 100
  availability_zones        = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_security_group_ids    = [var.security_groups_id]
  database_name             = "database_production"
  master_username           = "productionUser"
  master_password           = random_password.password.result
  backup_retention_period   = 7
  preferred_backup_window   = "03:00-06:00"
  deletion_protection       = true
  skip_final_snapshot       = true
  storage_encrypted         = true
  kms_key_id                = var.kms_key_id
  final_snapshot_identifier = "${var.name}-final-snapshot"
  apply_immediately         = true
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery",
  ]

  lifecycle {
    ignore_changes = ["final_snapshot_identifier", "snapshot_identifier", "master_password"]
  }
}

resource "aws_secretsmanager_secret_version" "rdsCredentials" {
  secret_id = aws_secretsmanager_secret.rdsCredentials.id
  secret_string = base64encode(jsonencode(
    {
      "development" : {
        "dialect" : "sqlite",
        "storage" : "./db.development.sqlite",
        "logging" : false
      },
      "test" : {
        "username" : "root",
        "password" : null,
        "database" : "database_test",
        "host" : "127.0.0.1",
        "dialect" : "mysql"
      },
      "production" : {
        "username" : "productionUser",
        "password" : random_password.password.result,
        "database" : aws_rds_cluster.default.database_name,
        "host" : aws_rds_cluster.default.endpoint,
        "port" : 3306,
        "dialect" : "mysql"
      }
  }))
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "goliive-aurora-${var.env}-${count.index}"
  cluster_identifier = aws_rds_cluster.default.id
  instance_class     = "db.t3.medium"
  apply_immediately  = true
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
}
