# Provider
variable "access_key" {}

variable "region" {}

variable "secret_key" {}

variable "token" {}

# Environment
variable "fqdn" {
  description = "Fully qualified domain name of cluster to deploy"
}

variable "kops-state-store" {
  description = "Name of s3 bucket containing kops cluster configurations"
}

# EC2 Key Pair
variable "ec2_pubkey" {
  description = "Contents of public key to upload to AWS to access Master and nodes.
      Make sure to have access to corresponding private key!"
}

# Configuration - Master
variable "master-ami" {
  default = "ami-66884c06"
}

variable "master-instance-type" {
  default = "m3.large"
}

variable "master-volume-size" {
  default = 20
}

# Configuration - Nodes
variable "nodes-ami" {
  default = "ami-66884c06"
}

variable "nodes-instance-type" {
  default = "t2.medium"
}

variable "nodes-volume-size" {
  default = 20
}

variable "nodes-min" {
  default = 2
}

variable "nodes-max" {
  default = 4
}

variable "nodes-desired" {
  default = 3
}
