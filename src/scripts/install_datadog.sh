#!/usr/bin/env bash
set -eo pipefail

echo "datadog install depends on python3."

if [[ "$DOG_VERSION" == "latest" ]]; then
    sudo pip install datadog
else
    sudo pip install datadog=="$DOG_VERSION"
fi

dog --version
