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

provider "ibm" {
  region           = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
}
