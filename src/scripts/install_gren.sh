#!/usr/bin/env bash
set -eo pipefail

echo "gren install depends on nodejs and npm."

if [[ "$GREN_VERSION" == "latest" ]]; then
    npm install -g github-release-notes
else
    npm install -g github-release-notes@"$GREN_VERSION"
fi

gren -v