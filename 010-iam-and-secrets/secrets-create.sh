#!/bin/bash
# APIKEY=
# REGION=
# SECRETS_MANAGER_ID=
# LOGGING_INGESTION_KEY=
# LOGGING_LOGS_HOST=
set -e -o pipefail

ibmcloud login --apikey $APIKEY -r $REGION
ibmcloud plugin install secrets-manager -f

secrets_manager_json=$(ibmcloud resource service-instance $SECRETS_MANAGER_ID --output json | jq '.[0]')
secrets_manager_url=https://$(echo $secrets_manager_json | jq -r '.extensions.virtual_private_endpoints | .dns_hosts[0]').${REGION}.secrets-manager.appdomain.cloud
echo "Secrets Manager URL is $secrets_manager_url"

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

echo '{
  "secret_group_id": "'$secret_group_id'",
  "logging_secret_id": "'$logging_secret_id'"
}' > secrets-create.json

ibmcloud logout
