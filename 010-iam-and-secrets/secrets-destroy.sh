#!/bin/bash
# APIKEY=
# REGION=
# SECRETS_MANAGER_ID=
set -e -o pipefail

# use IBM Cloud CLI to interact with Secrets Manager
ibmcloud login --apikey $APIKEY -r $REGION

# retrieve the URL of the Secrets Manager instance
secrets_manager_json=$(ibmcloud resource service-instance $SECRETS_MANAGER_ID --output json | jq '.[0]')
secrets_manager_url=https://$(echo $secrets_manager_json | jq -r '.extensions.virtual_private_endpoints | .dns_hosts[0]').${REGION}.secrets-manager.appdomain.cloud
echo "Secrets Manager URL is $secrets_manager_url"

# delete the secrets
ibmcloud sm secret-delete \
  --secret-type kv \
  --id $(cat ./secrets.json | jq -r .logging_secret_id) \
  --force \
  --service-url $secrets_manager_url

ibmcloud sm secret-delete \
  --secret-type kv \
  --id $(cat ./secrets.json | jq -r .monitoring_secret_id) \
  --force \
  --service-url $secrets_manager_url

# delete the secret group
ibmcloud sm secret-group-delete \
  --id $(cat ./secrets.json | jq -r .secret_group_id) \
  --force \
  --service-url $secrets_manager_url

ibmcloud logout

rm -f ./secrets.json
