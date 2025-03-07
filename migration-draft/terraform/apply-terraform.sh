#!/bin/bash

# Exit on error
set -e

# Get current user's object ID
CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Apply Terraform with the current user's object ID
terraform apply -var="current_user_object_id=$CURRENT_USER_OBJECT_ID" "$@" 