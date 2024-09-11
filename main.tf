provider "aws" {
  region = "eu-central-1"
}

# VPC
resource "aws_vpc" "feedback-app-terraform-docker-compose-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "feedback-app-terraform-docker-compose-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "feedback-app-terraform-docker-compose-igw" {
    vpc_id = aws_vpc.feedback-app-terraform-docker-compose-vpc.id
    tags = {
        Name = "feedback-app-terraform-docker-compose-igw"
  }
}

# Public subnet A (eu-central-1a)
resource "aws_subnet" "feedback-app-terraform-docker-compose-public-subnet-a" {
    vpc_id = aws_vpc.feedback-app-terraform-docker-compose-vpc.id
    cidr_block = "10.0.0.0/20"
    availability_zone = "eu-central-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "feedback-app-terraform-docker-compose-public-subnet-a"
  }
}

# Public subnet B (eu-central-1b)
resource "aws_subnet" "feedback-app-terraform-docker-compose-public-subnet-b" {
    vpc_id = aws_vpc.feedback-app-terraform-docker-compose-vpc.id
    cidr_block = "10.0.16.0/20"
    availability_zone = "eu-central-1b"
    map_public_ip_on_launch = true

    tags = {
        Name = "feedback-app-terraform-docker-compose-public-subnet-b"
  }
}

# Private subnet A (eu-central-1a)
resource "aws_subnet" "feedback-app-terraform-docker-compose-private-subnet-a" {
    vpc_id = aws_vpc.feedback-app-terraform-docker-compose-vpc.id
    cidr_block = "10.0.128.0/20"
    availability_zone = "eu-central-1a"

    tags = {
        Name = "feedback-app-terraform-docker-compose-private-subnet-a"
  }
}

# Private subnet B (eu-central-1b)
resource "aws_subnet" "feedback-app-terraform-docker-compose-private-subnet-b" {
    vpc_id = aws_vpc.feedback-app-terraform-docker-compose-vpc.id
    cidr_block = "10.0.144.0/20"
    availability_zone = "eu-central-1b"

    tags = {
        Name = "feedback-app-terraform-docker-compose-private-subnet-b"
  }
}

# Public Route Table 
resource "aws_route_table" "feedback-app-terraform-docker-compose-public-rtb" {
    vpc_id = aws_vpc.feedback-app-terraform-docker-compose-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.feedback-app-terraform-docker-compose-igw.id
    }

    tags = {
        Name = "feedback-app-terraform-docker-compose-public-rtb"
    }
}

# Public Subnet A to Public Route Table Association
resource "aws_route_table_association" "feedback-app-terraform-docker-compose-public-rtb-subnet-a-assoc" {
    subnet_id = aws_subnet.feedback-app-terraform-docker-compose-public-subnet-a.id
    route_table_id = aws_route_table.feedback-app-terraform-docker-compose-public-rtb.id
}

# Public Subnet B to Public Route Table Association
resource "aws_route_table_association" "feedback-app-terraform-docker-compose-public-rtb-subnet-b-assoc" {
    subnet_id = aws_subnet.feedback-app-terraform-docker-compose-public-subnet-b.id
    route_table_id = aws_route_table.feedback-app-terraform-docker-compose-public-rtb.id
}

# Security Group
resource "aws_security_group" "feedback-app-terraform-docker-compose-web-sg" {
    vpc_id = aws_vpc.feedback-app-terraform-docker-compose-vpc.id

    # HTTP (Port 80) Zugriff
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    } 

    # SSH (Port 22) Zugriff
    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    # Benutzerdefinierter Port TCP 3030
    ingress {
      from_port = 3030
      to_port = 3030
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "feedback-app-terraform-docker-compose-web-sg"
    }
}

# EC2 Instance - Web Server in Public Subnet A
resource "aws_instance" "feedback-app-terraform-docker-compose-web-server-a" {
  ami = "ami-0de02246788e4a354"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.feedback-app-terraform-docker-compose-public-subnet-a.id
  vpc_security_group_ids = [aws_security_group.feedback-app-terraform-docker-compose-web-sg.id]

  user_data = <<-EOF
                #!/bin/bash

                #Install Docker
                yum update -y
                yum install -y docker

                #Start Docker
                service docker start
                systemctl enable docker

                #Install Docker-Compose
                curl -L "https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose

                #Download Docker-Compose App Config
                mkdir /home/ec2-user/feedback-app
                cd /home/ec2-user/feedback-app
                wget https://raw.githubusercontent.com/kuigan/feedback-app/main/docker-compose.yml

                #Start the app
                docker-compose up -d
                EOF

  tags = {
    Name = "feedback-app-terraform-docker-compose-web-server-a"
  }
}

# EC2 Instance - Web Server in Public Subnet B
resource "aws_instance" "feedback-app-terraform-docker-compose-web-server-b" {
  ami = "ami-0de02246788e4a354"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.feedback-app-terraform-docker-compose-public-subnet-b.id
  vpc_security_group_ids = [aws_security_group.feedback-app-terraform-docker-compose-web-sg.id]

  user_data = <<-EOF
                #!/bin/bash

                #Install Docker
                yum update -y
                yum install -y docker

                #Start Docker
                service docker start
                systemctl enable docker

                #Install Docker-Compose
                curl -L "https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose

                #Download Docker-Compose App Config
                mkdir /home/ec2-user/feedback-app
                cd /home/ec2-user/feedback-app
                wget https://raw.githubusercontent.com/kuigan/feedback-app/main/docker-compose.yml

                #Start the app
                docker-compose up -d
                EOF

  tags = {
    Name = "feedback-app-terraform-docker-compose-web-server-b"
  }
}

# EC2 Instance - Web Server in Private Subnet A
resource "aws_instance" "feedback-app-terraform-docker-compose-web-server-private-a" {
  ami = "ami-0de02246788e4a354"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.feedback-app-terraform-docker-compose-private-subnet-a.id
  vpc_security_group_ids = [aws_security_group.feedback-app-terraform-docker-compose-web-sg.id]

  user_data = <<-EOF
                 #!/bin/bash

                #Install Docker
                yum update -y
                yum install -y docker

                #Start Docker
                service docker start
                systemctl enable docker

                #Install Docker-Compose
                curl -L "https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose

                #Download Docker-Compose App Config
                mkdir /home/ec2-user/feedback-app
                cd /home/ec2-user/feedback-app
                wget https://raw.githubusercontent.com/kuigan/feedback-app/main/docker-compose.yml

                #Start the app
                docker-compose up -d
                EOF

  tags = {
    Name = "feedback-app-terraform-docker-compose-web-server-private-a"
  }
}

# EC2 Instance - Web Server in Private Subnet B
resource "aws_instance" "feedback-app-terraform-docker-compose-web-server-private-b" {
  ami = "ami-0de02246788e4a354"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.feedback-app-terraform-docker-compose-private-subnet-b.id
  vpc_security_group_ids = [aws_security_group.feedback-app-terraform-docker-compose-web-sg.id]

  user_data = <<-EOF
                 #!/bin/bash

                #Install Docker
                yum update -y
                yum install -y docker

                #Start Docker
                service docker start
                systemctl enable docker

                #Install Docker-Compose
                curl -L "https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose

                #Download Docker-Compose App Config
                mkdir /home/ec2-user/feedback-app
                cd /home/ec2-user/feedback-app
                wget https://raw.githubusercontent.com/kuigan/feedback-app/main/docker-compose.yml

                #Start the app
                docker-compose up -d
                EOF

  tags = {
    Name = "feedback-app-terraform-docker-compose-web-server-private-b"
  }
}

# Outputs

output "instance_public_ip_a" {
    description = "The Public IP of the EC2 Instance in Public Subnet A"
    value = aws_instance.feedback-app-terraform-docker-compose-web-server-a.public_ip
}

output "instance_public_ip_b" {
    description = "The Public IP of the EC2 Instance in Public Subnet B"
    value = aws_instance.feedback-app-terraform-docker-compose-web-server-b.public_ip
}
