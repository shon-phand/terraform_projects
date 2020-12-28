provider "aws" {
  region     = "us-east-1"
}





resource "aws_default_vpc" "default" {
  tags = {
    "default" = "true"
    "Name"    = "Default_VPC_TF"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  name                 = "test_db_tf"
  username             = "shon"
  password             = "password"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  apply_immediately  = true
  security_group_names = [ aws_security_group.db.name ]
  depends_on           = [aws_default_vpc.default]
  
}

resource "aws_security_group" "db" {
  name        = "web-sg"
  description = "Allow  on port 3306"
 # vpc_id      = aws_vpc.custome-vpc.id

  ingress {
    description = "ssh from web"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
   # security_groups = [aws_security_group.appserver-sg.id]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "db-sg"
  }
}