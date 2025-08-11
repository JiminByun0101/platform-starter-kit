variable "project_id" { type = string }
variable "region" { type = string }
variable "network_name" { default = "psk-vpc" }
variable "subnet_name" { default = "psk-subnet" }
variable "subnet_cidr" { default = "10.10.0.0/24" }
variable "pods_cidr" { default = "10.20.0.0/16" }
variable "services_cidr" { default = "10.30.0.0/20" }
