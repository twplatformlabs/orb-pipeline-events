#!/usr/bin/env bash
set -eo pipefail

# add repository info for install of github cli
sudo mkdir -p /etc/apt/keyrings
sudo chmod 0755 /etc/apt/keyrings
sudo bash -c "curl -s https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null"
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

if [[ "$GH_CLI_VERSION" == "latest" ]]; then
  sudo apt-get install --no-install-recommends -y gh
else
  sudo apt-get install --no-install-recommends -y gh="$GH_CLI_VERSION"
fi

gh --version