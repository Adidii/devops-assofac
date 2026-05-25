provider "aws" {
  region = "eu-west-3"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "AssofacCloud-VPC" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
  tags = { Name = "Public-Subnet-A" }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3b"
  tags = { Name = "Public-Subnet-B" }
}

resource "aws_security_group" "db" {
  name        = "assofac-db-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group PostgreSQL"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "assofac-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.public_b.id]
}

resource "aws_db_instance" "postgres" {
  identifier           = "assofac-db"
  allocated_storage    = 20
  engine               = "postgres"
engine_version = "14.17"
  instance_class       = "db.t3.micro"
  db_name              = "assofacdb"
  username             = "admindb"
  password             = "Assofac2024!"
  skip_final_snapshot  = true
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  tags = { Name = "AssofacCloud-RDS" }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}