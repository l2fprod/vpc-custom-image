packer {
  required_plugins {
    ibmcloud = {
      version = ">=v2.1.0"
      source  = "github.com/IBM/ibmcloud"
    }
  }
}

variable "ibmcloud_api_key" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_id" {}
variable "resource_group_id" {}
variable "security_group_id" { default = "" }

variable "base_image_name" { default = "ibm-centos-7-9-minimal-amd64-8" }
variable "profile" { default = "bx2-2x8" }
variable "image_name" {
  default = ""
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  image_name = var.image_name == "" ? "packer-${local.timestamp}" : var.image_name
}

source "ibmcloud-vpc" "instance" {
  api_key = var.ibmcloud_api_key
  region  = var.region

  subnet_id         = var.subnet_id
  resource_group_id = var.resource_group_id
  security_group_id = var.security_group_id

  vsi_base_image_name = var.base_image_name
  vsi_profile         = var.profile
  vsi_interface       = "public"
  vsi_user_data_file  = ""

  image_name = local.image_name

  communicator = "ssh"
  ssh_username = "root"
  ssh_port     = 22
  ssh_timeout  = "15m"

  timeout = "60m"
}

build {
  sources = [
    "source.ibmcloud-vpc.instance"
  ]

  provisioner "shell" {
    inline = [ "mkdir -p /usr/local/on-boot/" ]
  }

  provisioner "file" {
    source = "./on-boot/"
    destination = "/usr/local/on-boot/"
  }

  provisioner "shell" {
    script = "./image-init.sh"
  }

  post-processor "manifest" {
    output = "output.json"
    custom_data = {
      image_name = local.image_name
    }
  }
}
