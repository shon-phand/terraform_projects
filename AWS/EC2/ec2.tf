provider "aws" {
  region     = "us-east-1"
}

variable key_name  {}



resource "aws_instance" "webserver" {
  ami                    = "ami-0be2609ba883822ec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1e"
  count                  = 2
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  key_name = var.key_name
  tags = {
    "Name" = "webserver-${count.index + 1}"
  }


}

# resource "aws_key_pair" "web-kp" {
#   key_name   = "web-kp"
#   public_key = file("./web-kp.pem")
# }

resource "aws_default_vpc" "default" {
  enable_dns_hostnames = true
  tags = {
    "default" = "true"
    "Name"    = "Default_VPC_TF"
  }
}


resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Allow  ssh and http 80"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "ssh from web"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "HTTP from web"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "webserver-sg"
  }
}