#!/bin/bash
set -e

if [[ "$1" == "clean" ]]; then
  rm -rf .terraform .terraform.lock.hcl terraform.tfstate*
  exit 0
fi

export TF_VAR_image_id=$(cat ../030-custom-image/output.json | jq -r '.builds[-1].artifact_id')

if [[ "$1" == "apply" ]]; then
  terraform init
  terraform apply
fi

if [[ "$1" == "destroy" ]]; then
  terraform destroy
fi

