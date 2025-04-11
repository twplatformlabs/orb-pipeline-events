#!/usr/bin/env bash
#shellcheck disable=SC1091
set -eo pipefail
source bash-functions.sh

committer_email=$1
committer_nanme=$2

# set committer
  git config --global user.email "$1"
  git config --global user.name "$2"

# generate monthly-recurring tag value
year=$(date +%Y)
month=$(date +%m)
tag="${year}.${month}"
echo "Generated tag: $tag"

tagCurrentRepo "$tag"