variable "existing_secrets_manager_id" {
}

variable "existing_log_analysis_crn" {
}

resource "ibm_resource_key" "logging_key" {
  name                 = "${var.basename}-logging-key"
  role                 = "Manager"
  resource_instance_id = var.existing_log_analysis_crn
}

resource "null_resource" "secrets_create" {

  triggers = {
    APIKEY                = var.ibmcloud_api_key
    REGION                = var.region
    SECRETS_MANAGER_ID    = var.existing_secrets_manager_id
    LOGGING_INGESTION_KEY = ibm_resource_key.logging_key.credentials.ingestion_key
    LOGGING_LOGS_HOST     = "logs.${var.region}.logging.cloud.ibm.com"
  }

  provisioner "local-exec" {
    command = "./secrets-create.sh"
    environment = {
      APIKEY                = self.triggers.APIKEY
      REGION                = self.triggers.REGION
      SECRETS_MANAGER_ID    = self.triggers.SECRETS_MANAGER_ID
      LOGGING_INGESTION_KEY = nonsensitive(ibm_resource_key.logging_key.credentials.ingestion_key)
      LOGGING_LOGS_HOST     = "logs.${var.region}.logging.cloud.ibm.com"
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "./secrets-destroy.sh"
    environment = {
      APIKEY             = self.triggers.APIKEY
      REGION             = self.triggers.REGION
      SECRETS_MANAGER_ID = self.triggers.SECRETS_MANAGER_ID
    }
  }
}

data "local_file" "secrets" {
  filename = "./secrets-create.json"

  depends_on = [null_resource.secrets_create]
}

locals {
  secrets_create = jsondecode(data.local_file.secrets.content)
}
