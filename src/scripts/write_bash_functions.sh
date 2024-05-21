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

# write1passwordField ()  ================================================================================
#
# update field value in 1password vault item, will creat item if it does not exists
# Expects parameters
# $1 = vault name
# $2 = item name
# $3 = field name
# $4 = new value
# Expects 1password service account credential to be present

write1passwordField () {
    set +e
    op item list --vault $1 | grep $2 >/dev/null
    exists=$?
    if [[ "$exists" == 1 ]]; then
        echo "$2 not found, creating..."
        echo "updating $3..."
        op item create --title="$2" --category 'API Credential' --vault "$1" "$3"="$4" >/dev/null
    else
        echo "updating $3..."
        op item edit "$2" "$3=$4" --vault $1 >/dev/null
    fi
    set -e
}

EOF
