
terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "java-app-bucket-1"
    key = "myapp/state.tfstate"
    region = "ap-southeast-1"
  }
}



provider "aws" {
    region = var.region
}




resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

/*resource "aws_route_table" "my-app-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-app-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}*/

resource "aws_internet_gateway" "my-app-igw" {
    vpc_id = aws_vpc.myapp-vpc.id

    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

/*resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.my-app-route-table.id
}*/


resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id


    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-app-igw.id
    }

    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }
}

resource "aws_default_security_group" "default-sg" { 
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip, var.jenkins_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name: "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}


/*resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDR+umvCnjLCJyTXA9dM8Nile/ldeBen953/94tin4WhbjXlf2KyO8BxTGexWv2LGUgoCsGuCJ1yaEKlmAhL9YK+uze+o3cOv1+dEfVMRBJGk1yxijEtG7VggkJg6OZ4bPxhJu6TDjGGVKEz6rWIzrS29S5LiMhee4WQTjWhPjfEofB60WTloART31o7Qv/NqXxpjVJO6o1ECr7shPohFjgtlbpSMoMT1itO+GiyN3wpiIPquThA0KIZNsurXwp42rmGUktrg7k4Fu58QsDddo+EZ8E61asKNtXJIhjbFRtBfUOkVugwXrpJhvIzHRQhg1LfoZ65gD9vTa8GSdAs5sttglnTwNOUhb74gj6DwWznK/oszlwsyf3zXGo0YjS/ej9OKQyutngEbEa35ISjNGxWSEIeo6/ZJARCxL8wSS8y3NbQM2h+x9xtNzgHjB45Aa8TKOWl1ZlpKS4PLSddlTQkm5TWQiTmEywj17iymHpo5lkX1S2ZaeaWxk+HaCso28= Rajib@DESKTOP-AHORTF8"
}
*/




resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true

    key_name = "myapp-key-pair"
    user_data = file("entry-script.sh")
    
    tags = {
        Name: "${var.env_prefix}-server"
    }
    
}
output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}
