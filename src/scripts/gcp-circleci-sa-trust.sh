#!/usr/bin/env bash
set -eo pipefail

WIP_ID=$1                                                     # workload identity pool id
WIP_SA_EMAIL=$2                                               # workload identity pool service account
OIDC_TOKEN_PATH=${3:-/home/circleci/oidc_token.json}          # write local instance of CircleCI OIDC token
GCP_CRED_FILE_PATH=${4:-/home/circleci/gcp_cred_config.json}  # write local instance of resulting credentials

# Store OIDC token in temp file
echo $CIRCLE_OIDC_TOKEN > $OIDC_TOKEN_PATH

# Create a credential configuration for the generated OIDC ID Token
gcloud iam workload-identity-pools create-cred-config $WIP_ID \
       --service-account=$WIP_SA_EMAIL \
       --credential-source-file=$OIDC_TOKEN_PATH \
       --output-file=$GCP_CRED_FILE_PATH

# Configure gcloud to leverage the generated credential configuration
gcloud auth login --brief --cred-file "$GCP_CRED_FILE_PATH"

# Configure ADC
echo "export GOOGLE_APPLICATION_CREDENTIALS=$GCP_CRED_FILE_PATH" | tee -a "$BASH_ENV"

# Verify authentication
gcloud iam service-accounts get-iam-policy "$WIP_SA_EMAIL"