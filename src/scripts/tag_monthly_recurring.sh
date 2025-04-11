#!/usr/bin/env bash
#shellcheck disable=SC1091
set -eo pipefail
source bash-functions.sh

# set committer
  echo "committer_email: $COMMITTER_EMAIL"
  echo "committer_email: $COMMITTER_NAME"
  git config --global user.email "$COMMITTER_EMAIL"
  git config --global user.name "$COMMITTER_NAME"

# generate monthly-recurring tag value
year=$(date +%Y)
month=$(date +%m)
tag="${year}.${month}"
echo "Generated tag: $tag"

tagCurrentRepo "$tag"