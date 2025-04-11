#!/usr/bin/env bash
set -eo pipefail
source bash-functions.sh

# generate monthly-recurring tag value
year=$(date +%Y)
month=$(date +%m)
tag="${year}.${month}"
echo "Generated tag: $tag"

tagCurrentRepo "$tag"