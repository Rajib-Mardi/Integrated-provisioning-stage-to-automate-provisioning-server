-CI-CD-with-Terraform

## Demo Project: 
* Complete CI/CD with Terraform
## Technologies used: 
* Terraform, Jenkins, Docker, AWS, Git, Java, Maven, Linux, Docker Hub
## Project Description: Integrate provisioning stage into complete CI/CD Pipeline to automate provisioning server instead of deploying to an existing server

## Create SSH key pair for EC2 Instance
* After creating the key pair, use the key pair to create new credentials in Jenkins with ssh as the user name as an ec2-user with a private key, and associate the key with instances when creating them with Terraform.

![Key pairs _ EC2 Management Console - Google Chrome 24-06-2023 23_14_38](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/7304dd9e-a6f3-4b36-89b6-387b4c1487d5)

## Created Credential in Jenkins
* Create credentials in Jenkins as an SSH user with a private key, name the credentials as username ec2-user with a private key, and associate the key with instances when creating them with Terraform.


![New credentials  Jenkins  and 6 more pages - Profile 1 - Microsoft​ Edge 22-06-2023 19_22_14](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/d54e80ae-98b3-4629-9956-f49f2e00cdc5)


## Install Terraform inside Jenkins Container

* SSH  into our digitalOcean droplet , inside the jenkins container as root user and install  the terraform
 

```
# add HashiCorp key
curl -fsSL https://apt.releases.hashicorp.com/gpg |  apt-key add -

# install apt-add-repo command
sudo apt-get install -y gnupg software-properties-common curl

# add the official HashiCorp Linux repository
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# update and install
apt-get update && apt-get install terraform

# verify
terraform -v
```

## Create Terraform configuration files to provision an ec2 server
*Make a folder called terraform that contains the terraform configuration files.
* Make a folder called terraform where the terraform configuration files will be located.
* In the main.tf file, create a vpc with 1 subnet, an internet gateway, default route tables, default security groups, and EC2 instances.

* In variables.tf file defined the 

```terraform
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

resource "aws_internet_gateway" "my-app-igw" {
    vpc_id = aws_vpc.myapp-vpc.id

    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

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
```


## Create entry-script.sh file to install docker, docker-compose and start containers through docker-compose command
 


