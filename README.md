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
