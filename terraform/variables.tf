variable vpc_cidr_block {
    default = "10.0.0.0/16"
}
variable subnet_cidr_block {
    default = "10.0.10.0/24"
}

variable avail_zone {
    default = "ap-southeast-1a"
}

variable env_prefix {
    default = "dev"
}

variable my_ip {
    default = "202.173.124.140/32"
}
variable jenkins_ip {
    default = "165.227.153.209/32"
}

variable instance_type {
    default = "t2.micro"
}
variable region {
    default = "ap-southeast-1"
}
