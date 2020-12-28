# getting all availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

#crating a custom vpc
resource "aws_vpc" "custome-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "Custom_VPC"
  }
}

# adding a internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custome-vpc.id

  tags = {
    Name = "TF-IG"
  }
}

# creating public subnets

resource "aws_subnet" "public-sn" {
  count                   = 2
  vpc_id                  = aws_vpc.custome-vpc.id
  cidr_block              = var.public-sn[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-sn-${count.index + 1}"
  }
}

# creating private subnets

resource "aws_subnet" "private-sn" {
  count                   = 2
  vpc_id                  = aws_vpc.custome-vpc.id
  cidr_block              = var.private-sn[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "private-sn-${count.index + 1}"
  }
}

#creating a public route table

resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.custome-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "public route table"
  }
}
#route table- public subnet association association
resource "aws_route_table_association" "public-subnet-association" {
  count          = length(aws_subnet.public-sn)
  subnet_id      = aws_subnet.public-sn[count.index].id
  route_table_id = aws_route_table.public-route.id
}

# creating a NAT GW
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-sn[0].id

  tags = {
    Name = "gw NAT"
  }
}

#creating a eip
resource "aws_eip" "nat-eip" {
  vpc = true
}

# private rout table

resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.custome-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }


  tags = {
    Name = "private route table"
  }
}


#route table- priavate subnet association association
resource "aws_route_table_association" "private-subnet-association" {
  count          = length(aws_subnet.private-sn)
  subnet_id      = aws_subnet.private-sn[count.index].id
  route_table_id = aws_route_table.private-route.id
}

# creating a ec2 instances
variable "key_name" {}
resource "aws_instance" "webserver" {
  ami                         = "ami-0be2609ba883822ec"
  instance_type               = "t2.micro"
  count                       = 2
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-sn[count.index].id
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  key_name                    = var.key_name
  user_data                   = <<-EOF
		#!/bin/bash
    sudo su root
    sudo yum install epel-release -y
		sudo yum install nginx -y
		sudo systemctl start nginx
    sudo systemctl enable nginx
		echo "<h1>Deployed via Terraform</h1>" | sudo tee /usr/share/nginx/html/index.html
    EOF

  tags = {
    "Name" = "webserver-${count.index + 1}"
  }


}


# creating webserver security group
resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Allow  ssh and http 80"
  vpc_id      = aws_vpc.custome-vpc.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "webserver-sg"
  }
}

#creating aperserver

resource "aws_instance" "appserver" {
  ami                         = "ami-0be2609ba883822ec"
  instance_type               = "t2.micro"
  count                       = 2
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.private-sn[count.index].id
  vpc_security_group_ids      = [aws_security_group.app-sg.id]
  key_name                    = var.key_name
  user_data                   = <<-EOF
		#!/bin/bash
    sudo yum install epel-release -y
    sudo yum update -y
    sudo yum install git -y
    sudo yum install golang -y
    wget https://github.com/shon-phand/Go-Programs.git
    go run ./Go-Programs/main.go
    EOF

  tags = {
    "Name" = "appserver-${count.index + 1}"
  }
  
  depends_on = [ aws_route_table.private-route ]

}
#creating appserver security group

resource "aws_security_group" "app-sg" {
  name        = "app-sg"
  description = "Allow  ssh and http 8080"
  vpc_id      = aws_vpc.custome-vpc.id

  ingress {
    description = "ssh from web"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.web-sg.id]
    
  }

  ingress {
    description = "HTTP from web"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.web-sg.id]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "appserver-sg"
  }
}