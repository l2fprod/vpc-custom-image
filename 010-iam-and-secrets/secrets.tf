variable "existing_secrets_manager_id" {
}

variable "existing_log_analysis_crn" {
}

variable "existing_monitoring_crn" {
}

resource "ibm_resource_key" "logging_key" {
  name                 = "${var.basename}-logging-key"
  role                 = "Manager"
  resource_instance_id = var.existing_log_analysis_crn
}

resource "ibm_resource_key" "monitoring_key" {
  name                 = "${var.basename}-monitoring-key"
  role                 = "Manager"
  resource_instance_id = var.existing_monitoring_crn
}

resource "ibm_sm_secret_group" "secret_group" {
  instance_id = var.existing_secrets_manager_id
  name        = "custom-image-observability"
  description = "Created by terraform as part of the custom-image example"
}

resource "ibm_sm_kv_secret" "logging" {
  instance_id = var.existing_secrets_manager_id
  name = "custom-image-logging"
  secret_group_id = ibm_sm_secret_group.secret_group.secret_group_id
  data = {
    log_host = "logs.${var.region}.logging.cloud.ibm.com"
    ingestion_key = ibm_resource_key.logging_key.credentials.ingestion_key
  }
}

resource "ibm_sm_kv_secret" "monitoring" {
  instance_id = var.existing_secrets_manager_id
  name = "custom-image-monitoring"
  secret_group_id = ibm_sm_secret_group.secret_group.secret_group_id
  data = {
    host = "ingest.private.${var.region}.monitoring.cloud.ibm.com",
    access_key = ibm_resource_key.monitoring_key.credentials["Sysdig Access Key"]
  }
}
