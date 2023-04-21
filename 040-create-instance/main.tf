data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../020-prepare-custom-image/terraform.tfstate"
  }
}

data "terraform_remote_state" "iam" {
  backend = "local"

  config = {
    path = "../010-iam-and-secrets/terraform.tfstate"
  }
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "ibmcloud_api_key" {
  description = "IBM Cloud API key to create resources"
}

variable "region" {
  default = "us-south"
}

variable "tags" {
  default = ["terraform", "custom-image"]
}

variable "image_id" {}
variable "ssh_key_name" {}

provider "ibm" {
  region           = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
}

data "ibm_is_image" "image" {
  identifier = var.image_id
}

data "ibm_is_ssh_key" "key" {
  name = var.ssh_key_name
}

resource "ibm_is_instance" "instance" {
  name                           = "${data.terraform_remote_state.vpc.outputs.basename}-test"
  image                          = data.ibm_is_image.image.id
  profile                        = "bx2-2x8"
  default_trusted_profile_target = data.terraform_remote_state.iam.outputs.trusted_profile_id

  metadata_service {
    enabled = true
  }

  vpc            = data.terraform_remote_state.vpc.outputs.vpc.id
  zone           = "${var.region}-1"
  keys           = [data.ibm_is_ssh_key.key.id]
  resource_group = data.terraform_remote_state.vpc.outputs.resource_group_id

  primary_network_interface {
    subnet          = data.terraform_remote_state.vpc.outputs.subnet_id
    security_groups = [data.terraform_remote_state.vpc.outputs.security_group_id]
  }

  boot_volume {
    name = "${data.terraform_remote_state.vpc.outputs.basename}-test-boot"
  }

  tags = var.tags
}

resource "ibm_is_floating_ip" "fip" {
  name   = "${data.terraform_remote_state.vpc.outputs.basename}-test-ip"
  target = ibm_is_instance.instance.primary_network_interface[0].id
}

output "hostname" {
  value = ibm_is_instance.instance.name
}

output "ip" {
  value = ibm_is_floating_ip.fip.address
}

output "ssh" {
  value = "ssh root@${ibm_is_floating_ip.fip.address}"
}
