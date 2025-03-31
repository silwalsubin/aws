resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "aurora-postgres-cluster"
  engine                 = "aurora-postgresql"
  engine_version         = "13.16"
  database_name          = "mydatabase"
  master_username        = "admin"
  master_password        = "your-secure-password"
  skip_final_snapshot    = true
  backup_retention_period = 7
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
}