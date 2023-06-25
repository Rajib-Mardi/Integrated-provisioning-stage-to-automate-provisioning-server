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
* create a credentials in jenkins as SSH Username with private key and name the credentials as username as ec2-user with private key.

![New credentials  Jenkins  and 6 more pages - Profile 1 - Microsoft​ Edge 22-06-2023 19_22_14](https://github.com/Rajib-Mardi/Demo-Project-3-CI-CD-with-Terraform/assets/96679708/d54e80ae-98b3-4629-9956-f49f2e00cdc5)


