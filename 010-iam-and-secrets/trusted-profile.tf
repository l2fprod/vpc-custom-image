# trusted profile for VPC resources
resource "ibm_iam_trusted_profile" "profile" {
  name = "${var.basename}-vsi-profile"
}

resource "ibm_iam_trusted_profile_policy" "view_secrets_manager" {
  profile_id = ibm_iam_trusted_profile.profile.id
  roles      = ["Viewer"]

  resources {
    service              = "secrets-manager"
    resource_instance_id = var.existing_secrets_manager_id
  }
}

resource "ibm_iam_trusted_profile_policy" "view_secret_group" {
  profile_id = ibm_iam_trusted_profile.profile.id
  roles      = ["SecretsReader"]

  resources {
    service              = "secrets-manager"
    resource_instance_id = var.existing_secrets_manager_id
    resource_type        = "secret-group"
    resource             = ibm_sm_secret_group.secret_group.secret_group_id
  }
}

output "trusted_profile_id" {
  value = ibm_iam_trusted_profile.profile.id
}
