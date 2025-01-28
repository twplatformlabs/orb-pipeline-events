#!/usr/bin/env bash
set -eo pipefail

install_alpine() {
  if [[ "$GH_CLI_VERSION" == "latest" ]];
    sudo apk add --no-cache github-cli
  else
    sudo apk add --no-cache github-cli=="$GH_CLI_VERSION"
  fi
}

install_ubuntu() {
  if [[ "$GH_CLI_VERSION" == "latest" ]];
    sudo apt-get install --no-install-recommends -y gh
  else
    sudo apt-get install --no-install-recommends -y gh="$GH_CLI_VERSION"
  fi

}

if [[ "$OS" == "Alpine" ]]; then
    install_alpine
elif [[ "$OS" == "Ubuntu" ]]; then
    install_ubuntu
fi

gh --version