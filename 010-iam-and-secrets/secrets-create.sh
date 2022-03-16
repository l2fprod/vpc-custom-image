#!/bin/bash
# APIKEY=
# REGION=
# SECRETS_MANAGER_ID=
# LOGGING_INGESTION_KEY=
# LOGGING_LOGS_HOST=
# MONITORING_ACCESS_KEY=
# MONITORING_HOST=
set -e -o pipefail

# use IBM Cloud CLI to interact with Secrets Manager
ibmcloud login --apikey $APIKEY -r $REGION
ibmcloud plugin install secrets-manager -f

# retrieve the URL of the Secrets Manager instance
secrets_manager_json=$(ibmcloud resource service-instance $SECRETS_MANAGER_ID --output json | jq '.[0]')
secrets_manager_url=https://$(echo $secrets_manager_json | jq -r '.extensions.virtual_private_endpoints | .dns_hosts[0]').${REGION}.secrets-manager.appdomain.cloud
echo "Secrets Manager URL is $secrets_manager_url"

# create a secret group
echo "Creating a secret group..."
secret_group_json=$(\
ibmcloud secrets-manager secret-group-create \
  --metadata='{
    "collection_type": "application/vnd.ibm.secrets-manager.secret.group+json",
    "collection_total": 1
  }' \
  --resources='[
    {
      "name": "custom-image-observability",
       "description": "Created by terraform as part of the custom-image example."
    }
  ]' \
  --output json \
  --service-url $secrets_manager_url \
)
secret_group_id=$(echo $secret_group_json | jq -r .resources[0].id)
echo "Secret group ID is $secret_group_id"

# create a secret for Log Analysis agent
echo "Creating logging secret..."
logging_secret_json=$(\
ibmcloud secrets-manager secret-create \
  --secret-type kv \
  --metadata='{"collection_type": "application/vnd.ibm.secrets-manager.config+json", "collection_total": 1}' \
  --resources='[
    {
      "name": "custom-image-logging",
      "secret_group_id": "'$secret_group_id'",
      "payload": {
        "log_host": "'$LOGGING_LOGS_HOST'",
        "ingestion_key": "'$LOGGING_INGESTION_KEY'"
      }
    }
  ]' \
  --output json \
  --service-url $secrets_manager_url \
)
logging_secret_id=$(echo $logging_secret_json | jq -r .resources[0].id)
echo "Logging secret ID is $logging_secret_id"

# create a secret for Monitoring agent
echo "Creating monitoring secret..."
monitoring_secret_json=$(\
ibmcloud secrets-manager secret-create \
  --secret-type kv \
  --metadata='{"collection_type": "application/vnd.ibm.secrets-manager.config+json", "collection_total": 1}' \
  --resources='[
    {
      "name": "custom-image-monitoring",
      "secret_group_id": "'$secret_group_id'",
      "payload": {
        "host": "'$MONITORING_HOST'",
        "access_key": "'$MONITORING_ACCESS_KEY'"
      }
    }
  ]' \
  --output json \
  --service-url $secrets_manager_url \
)
monitoring_secret_id=$(echo $monitoring_secret_json | jq -r .resources[0].id)
echo "monitoring secret ID is $monitoring_secret_id"

# write down output in a format than can be consumed by terraform
echo '{
  "secret_group_id": "'$secret_group_id'",
  "logging_secret_id": "'$logging_secret_id'",
  "monitoring_secret_id": "'$monitoring_secret_id'"
}' > secrets.json

ibmcloud logout
