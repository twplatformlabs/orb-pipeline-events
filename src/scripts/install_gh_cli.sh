#!/usr/bin/env bash
set -eo pipefail

if [[ "$GH_CLI_VERSION" == "latest" ]]; then
  sudo apt-get install --no-install-recommends -y gh
else
  sudo apt-get install --no-install-recommends -y gh="$GH_CLI_VERSION"
fi

gh --version