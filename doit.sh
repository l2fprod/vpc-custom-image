#!/bin/bash
set -e -o pipefail

if [[ "$1" == "apply" ]]; then
  tfswitch || true
  (cd 010-iam-and-secrets && ./main.sh apply)
  (cd 020-prepare-custom-image && ./main.sh apply)
  (cd 030-custom-image && ./main.sh apply)
  (cd 040-create-instance && ./main.sh apply)
fi

if [[ "$1" == "destroy" ]]; then
  (cd 040-create-instance && ./main.sh destroy) || true
  (cd 030-custom-image && ./main.sh destroy) || true
  (cd 020-prepare-custom-image && ./main.sh destroy) || true
  (cd 010-iam-and-secrets && ./main.sh destroy) || true
fi

if [[ "$1" == "clean" ]]; then
  (cd 040-create-instance && ./main.sh clean) || true
  (cd 030-custom-image && ./main.sh clean) || true
  (cd 020-prepare-custom-image && ./main.sh clean) || true
  (cd 010-iam-and-secrets && ./main.sh clean) || true
  exit 0
fi
