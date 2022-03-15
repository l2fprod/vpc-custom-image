#!/bin/bash
# This script is called when an instance created from the image starts.
# This script was registered as a service when the image was created

# retrieve information from meta data service
echo "on-boot initialization!"

# token to talk to meta data service
echo "Retrieving instance identity token..."
export IBMCLOUD_CR_TOKEN=$(curl -X PUT "http://169.254.169.254/instance_identity/v1/token?version=2022-02-15" \
  -H "Metadata-Flavor: ibm" \
  -H "Accept: application/json" \
  -d '{ "expires_in": 300 }' | jq -r '.access_token' \
)

# trusted profile configured during instance creation
echo "Retrieving instance default trusted profile id..."
export IBMCLOUD_CR_PROFILE=$(curl -X GET "http://169.254.169.254/metadata/v1/instance/initialization?version=2022-03-01" \
  -H "Authorization: Bearer $IBMCLOUD_CR_TOKEN" | \
  jq -r .default_trusted_profile.target.id \
)
echo "Trusted profile id is $IBMCLOUD_CR_PROFILE"

# point the script to the directory where .bluemix is with all plugins
export IBMCLOUD_HOME=/root

# login with token and profile
ibmcloud login -r us-south

# retrieve the secrets manager instance
echo "Retrieving all services..."
services_json=$(ibmcloud resource service-instances --output json)

echo "Retrieving Secrets Manager instance..."
secrets_manager_json=$(echo $services_json | jq '[.[] | select(.id | contains(":secrets-manager:"))][0]')

secrets_manager_url=https://$(echo $secrets_manager_json | jq -r '.extensions.virtual_private_endpoints | .dns_hosts[0] + "." + .dns_domain')
echo "Secrets Manager URL is $secrets_manager_url"

echo "Retrieving secret groups..."
secret_groups_json=$(ibmcloud sm secret-groups --service-url $secrets_manager_url --output json)

# retrieve the id of the "observability" secret group
observability_group_id=$(echo $secret_groups_json | jq -r '.resources[] | select(.name=="custom-image-observability") | .id')
echo "Found custom-image-observability group id $observability_group_id"

# retrieve the secrets in the group
echo "Retrieving secrets from secret group..."
observability_group_secrets_json=$(ibmcloud sm all-secrets --groups $observability_group_id --service-url $secrets_manager_url  --output json)

# and their id
logging_secret_id=$(echo $observability_group_secrets_json | jq -r '.resources[] | select(.name=="custom-image-logging") | .id')
echo "logging secret id is $logging_secret_id"

echo "Retrieving logging secret..."
logging_secret_json=$(ibmcloud sm secret --id $logging_secret_id --secret-type kv --service-url $secrets_manager_url --output json)

# configure Log Analysis agent
# https://github.com/logdna/logdna-agent-v2/blob/3.3/docs/LINUX.md
echo "Creating Log Analysis agent configuration file..."
cat > /etc/logdna.env << EOF
LOGDNA_HOST=$(echo $logging_secret_json | jq -r '.resources[0].secret_data.payload.log_host')
LOGDNA_INGESTION_KEY=$(echo $logging_secret_json | jq -r '.resources[0].secret_data.payload.ingestion_key')
EOF

echo "Starting Log Analysis agent..."
systemctl enable logdna-agent
systemctl restart logdna-agent
systemctl status logdna-agent
