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

# Kubernetes Assets
variable "kube-assets" {
  description = "This populates the user-data for master and nodes with recent versions of kube"
  default = "- 5a20cef330315a99773549cec4131edb8e53002a@https://storage.googleapis.com/kubernetes-release/release/v1.4.1/bin/linux/amd64/kubelet
- b297821f101e685e4072c15028008e12ff3a59e3@https://storage.googleapis.com/kubernetes-release/release/v1.4.1/bin/linux/amd64/kubectl
- 86966c78cc9265ee23f7892c5cad0ec7590cec93@https://storage.googleapis.com/kubernetes-release/network-plugins/cni-8a936732094c0941e1543ef5d292a1f4fffa1ac5.tar.gz"
}

variable "nodeup-url" {
  description = "Recent version for nodeup url for user-data"
  default = "https://kubeupv2.s3.amazonaws.com/kops/1.3/linux/amd64/nodeup"
}
