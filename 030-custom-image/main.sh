#!/bin/bash
set -e

if [[ "$1" == "clean" ]]; then
  exit 0
fi

# initialize variable used by the Packer build
export PKR_VAR_ibmcloud_api_key=$TF_VAR_ibmcloud_api_key
export PKR_VAR_region=$TF_VAR_region
export PKR_VAR_image_name=$(cd ../020-prepare-custom-image && terraform output -raw basename)-$(date +%Y-%m-%d-%H-%M-%S-%N)
export PKR_VAR_subnet_id=$(cd ../020-prepare-custom-image && terraform output -raw subnet_id)
export PKR_VAR_resource_group_id=$(cd ../020-prepare-custom-image && terraform output -raw resource_group_id)
export PKR_VAR_security_group_id=$(cd ../020-prepare-custom-image && terraform output -raw security_group_id)

if [[ "$1" == "apply" ]]; then
  packer init -upgrade vm.pkr.hcl
  packer validate vm.pkr.hcl
  packer build vm.pkr.hcl
fi

if [[ "$1" == "destroy" ]]; then
  ibmcloud login --apikey $PKR_VAR_ibmcloud_api_key -r $PKR_VAR_region -g $PKR_VAR_resource_group_id
  for imageId in $(cat output.json | jq -r '.builds[]| .artifact_id'); do
    ibmcloud is image-delete $imageId -f || true
  done
  rm -f ./output.json
fi
