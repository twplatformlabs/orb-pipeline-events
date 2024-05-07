#!/usr/bin/env bash
#shellcheck disable=SC2155,SC2002
set -eo pipefail

cat << 'EOF' > bash-functions.sh
# shared bash functions

# awsAssumeRole ()  ================================================================================
#
# Assume AWS role.
# Expects parameters
# $1 = aws accounts id
# $2 = aws role to assume
# Expects IAM credentials to be defined as ENV variables

awsAssumeRole () {
    aws sts assume-role --output json --role-arn arn:aws:iam::"$1":role/"$2" --role-session-name aws-assume-role > credentials

    export AWS_ACCESS_KEY_ID=$(cat credentials | jq -r ".Credentials.AccessKeyId")
    export AWS_SECRET_ACCESS_KEY=$(cat credentials | jq -r ".Credentials.SecretAccessKey")
    export AWS_SESSION_TOKEN=$(cat credentials | jq -r ".Credentials.SessionToken")
}

EOF
