#!/usr/bin/env bash
#shellcheck disable=SC1091
set -eo pipefail
source bash-functions.sh

committer_email=$1
committer_name=$2

# set committer
  git config --global user.email "$committer_email"
  git config --global user.name "$committer_name"

# generate monthly-recurring tag value
year=$(date +%Y)
month=$(date +%m)
tag="${year}.${month}"
echo "Generated tag: $tag"

tagCurrentRepo "$tag"