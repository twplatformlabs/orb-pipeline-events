#!/usr/bin/env bash
set -eo pipefail

# expected ENV
# WIP_ID              workload identity pool id
# WIP_SA_EMAIL        workload identity pool service account
# OIDC_TOKEN_PATH     write local instance of CircleCI OIDC token
# GCP_CRED_FILE_PATH  write local instance of resulting credentials

echo "Creating workload-identity-pool credentials for"
echo "WIP_ID: $WIP_ID"
echo "WIP_SA_EMAIL: $WIP_SA_EMAIL"

# Store OIDC token in temp file
echo "$CIRCLE_OIDC_TOKEN" > "$OIDC_TOKEN_PATH"

# Create a credential configuration for the generated OIDC ID Token
gcloud iam workload-identity-pools create-cred-config "$WIP_ID" \
       --service-account="$WIP_SA_EMAIL" \
       --credential-source-file="$OIDC_TOKEN_PATH" \
       --output-file="$GCP_CRED_FILE_PATH"

# Configure gcloud to leverage the generated credential configuration
gcloud auth login --brief --cred-file "$GCP_CRED_FILE_PATH"

# Configure ADC
echo "export GOOGLE_APPLICATION_CREDENTIALS=$GCP_CRED_FILE_PATH" | tee -a "$BASH_ENV"

# Verify authentication
gcloud iam service-accounts get-iam-policy "$WIP_SA_EMAIL"
