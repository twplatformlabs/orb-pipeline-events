#!/usr/bin/env bash
set -eo pipefail

echo "gren install depends on nodejs and npm."

if [[ "$GREN_VERSION" == "latest" ]]; then
    npm install -g gren
else
    npm install -g gren@"$GREN_VERSION"
fi

gren -v