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
  default     = "us-south"
  description = "Region where to find and create resources"
}

variable "basename" {
  default     = "custom-image"
  description = "Prefix for all resources created by the template"
}

variable "existing_resource_group_name" {
  default = ""
}

variable "tags" {
  default = ["terraform", "custom-image"]
}

variable "vpc_cidr" {
  default = "10.10.10.0/24"
}

provider "ibm" {
  region           = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
}

#
# Create a resource group or reuse an existing one
#
resource "ibm_resource_group" "group" {
  count = var.existing_resource_group_name != "" ? 0 : 1
  name  = "${var.basename}-group"
  tags  = var.tags
}

data "ibm_resource_group" "group" {
  count = var.existing_resource_group_name != "" ? 1 : 0
  name  = var.existing_resource_group_name
}

locals {
  resource_group_id = var.existing_resource_group_name != "" ? data.ibm_resource_group.group.0.id : ibm_resource_group.group.0.id
}

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.basename}-vpc"
  resource_group            = local.resource_group_id
  address_prefix_management = "manual"
  tags                      = concat(var.tags, ["vpc"])
}

resource "ibm_is_vpc_address_prefix" "subnet_prefix" {
  name = "${var.basename}-zone-1"
  zone = "${var.region}-1"
  vpc  = ibm_is_vpc.vpc.id
  cidr = var.vpc_cidr
}

resource "ibm_is_network_acl" "network_acl" {
  name           = "${var.basename}-acl"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = local.resource_group_id

  rules {
    name        = "egress"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
  rules {
    name        = "ingress"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
}

resource "ibm_is_subnet" "subnet" {
  name            = "${var.basename}-subnet"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.region}-1"
  resource_group  = local.resource_group_id
  ipv4_cidr_block = ibm_is_vpc_address_prefix.subnet_prefix.cidr
  network_acl     = ibm_is_network_acl.network_acl.id
  tags            = concat(var.tags, ["vpc"])
}

resource "ibm_is_security_group" "group" {
  name           = "${var.basename}-sg"
  resource_group = local.resource_group_id
  vpc            = ibm_is_vpc.vpc.id
  tags           = concat(var.tags, ["vpc"])
}

resource "ibm_is_security_group_rule" "inbound_ssh" {
  group     = ibm_is_security_group.group.id
  direction = "inbound"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "outbound_http" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  tcp {
    port_max = 80
    port_min = 80
  }
}

resource "ibm_is_security_group_rule" "outbound_https" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  tcp {
    port_max = 443
    port_min = 443
  }
}

resource "ibm_is_security_group_rule" "outbound_dns" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  udp {
    port_max = 53
    port_min = 53
  }
}

resource "ibm_is_security_group_rule" "outbound_cse" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  remote    = "166.9.0.0/16"
}

output "vpc" {
  value = ibm_is_vpc.vpc
}

output "subnet_id" {
  value = ibm_is_subnet.subnet.id
}

output "resource_group_id" {
  value = local.resource_group_id
}

output "security_group_id" {
  value = ibm_is_security_group.group.id
}

output "basename" {
  value = var.basename
}
