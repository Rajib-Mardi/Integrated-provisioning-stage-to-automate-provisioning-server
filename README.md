CI_CD with Terraform

<p float="left">
<img src="https://github.com/appwebtech/EKS-Cluster-With-Terraform/blob/main/images/tf-logo.png" width="100">


<img src="https://github.com/appwebtech/Ansible-Integration-Jenkins/blob/main/images/aws-logo.png" width="120">


<img src="https://github.com/appwebtech/Deploy-Docker-With-Terraform/blob/main/images/docker.png" width="100">
</p>

----

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
 
## Adjust Jenkinsfile to include provision terraform and deployment stage


```jenkins 
       stage('provision server') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                TF_VAR_env_prefix = 'test'
            }
            steps {
                script {
                    dir('terraform') {
                        sh "terraform init"
                        sh "terraform apply --auto-approve"
                        EC2_PUBLIC_IP = sh(
                            script: "terraform output ec2_public_ip",
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }



`````

       stage('deploy') {
            environment {
                DOCKER_CREDS = credentials('docker-hub-repo')
            }
            steps {
                script {
                   echo "waiting for EC2 server to initialize" 
                   sleep(time: 90, unit: "SECONDS") 

                   echo 'deploying docker image to EC2...'
                   echo "${EC2_PUBLIC_IP}"

                   echo 'deploying docker image to EC2'
                   def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"
                   def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"

                   sshagent(['server-ssh-key']) {
                       sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${ec2Instance}:/home/ec2-user"
                       sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ${ec2Instance}:/home/ec2-user"
                       sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
                    }

                }   
            }
        }



## Include docker login to be able to pull Docker Images from private Docker repository
* docker login on ec2 server so ec2 server can authenticate with docker repository.
* We need  the login user and password in the script to execute on the EC2 server.

![server-cmds sh - java-maven-app - Visual Studio Code 25-06-2023 21_12_23](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/f8bfaf7b-9e71-4ea1-bca6-0b3a40014b6b)


* We can get the login user and password in the Jenkinsfile from the Docker credentials that we have created in Jenkins and use as the environment variables  in  the  jenkinsfile.



![Jenkinsfile - java-maven-app - Visual Studio Code 25-06-2023 21_15_08](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/3c9c2361-fd29-4e1e-b2ab-ad7ec0dd23cc)


 ## Execute CI/CD pipeline

* As we can see, the pipeline has been successfully run.

![java-maven-app » featture_jenkins-sshagent-terraform #13 Console  Jenkins  - Google Chrome 21-06-2023 23_50_24](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/d79daf4f-629e-4315-a54d-06d9079fa7bd)

 ## We can see if the container is running by sshing into the server.

 ![ec2-user@ip-10-0-10-212_~ 21-06-2023 23_49_59](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/0d1cd521-fcc8-485d-90cf-3d57546f1457)

## In the AWS console, we can see that a vpc, subnet, security groups, route table, internet gateway, and instances have  been created.

   



![Your VPCs _ VPC Management Console - Google Chrome 21-06-2023 23_56_28](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/c66d45d9-a0a6-4589-9d7c-6ad5504c8c9d)


![Your VPCs _ VPC Management Console - Google Chrome 21-06-2023 23_56_43](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/836318b8-5f2f-47e9-b54a-da0e4c94002c)


 ![Your VPCs _ VPC Management Console - Google Chrome 21-06-2023 23_56_54](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/3c0a1df3-aafa-4464-a190-fe0d01440012)


 
![Your VPCs _ VPC Management Console - Google Chrome 21-06-2023 23_57_03](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/7f00e8cf-4e5e-4448-b32e-0ae4619edb5b)


![Your VPCs _ VPC Management Console - Google Chrome 21-06-2023 23_57_15](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/e8bbcbe0-9a4b-4f7f-91f9-3e936dee6ba4)

![Your VPCs _ VPC Management Console - Google Chrome 21-06-2023 23_57_37](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/c4e1ae05-7278-460c-bb7c-141981ed2ac9)

----------------------------------------

## Demo Project: 
* Configure a Shared Remote State
## Technologiesused: 
* Terraform, AWS S3
## Project Description:
* Configure Amazon S3 as remote storage for Terraform state

## create AWS S3 Bucket

* In terraform main.tf, configure the s3 bucket to store the state.tfstate file data.

```terraform
terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "java-app-bucket-1"
    key = "myapp/state.tfstate"
    region = "ap-southeast-1"
  }
}
```


![S3 bucket - Google Chrome 26-06-2023 00_08_55](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/e1d01112-23ef-4278-879e-3bdd6f046271)

* Enable the bucket version

## Run the CI-CD pipeline 

![featture_jenkins-sshagent-terraform  java-maven-app   Jenkins  and 7 more pages - Profile 1 - Microsoft​ Edge 22-06-2023 20_55_51](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/af0deda8-dc5a-4cd5-b735-25723bac1513)


## We can see the Terraform state file has been created successfully.


![EC2 Management Console - Google Chrome 22-06-2023 21_18_49](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/f238c3d6-30fe-479a-9a0f-cbb316eab7c6)

