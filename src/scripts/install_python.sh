#!/usr/bin/env bash
set -eo pipefail

if [[ "$OS" == "Alpine" ]]; then
    if [[ "$PYTHON_VERSION" == "latest" ]]; then
        sudo apk add --no-cache python3-dev
    else
        sudo apk add --no-cache python3-dev=="$PYTHON_VERSION"
    fi
    sudo rm -r /usr/lib/python*/ensurepip
    sudo pip3 install --upgrade pip
    if [ ! -e /usr/bin/pip ]; then sudo ln -s /usr/bin/pip3 /usr/bin/pip ; fi
    sudo ln -s /usr/bin/pydoc3 /usr/bin/pydoc
elif [[ "$OS" == "Ubuntu" ]]; then
    sudo apt-get update
    if [[ "$PYTHON_VERSION" == "latest" ]]; then
        sudo apt-get install --no-install-recommends -y python3-dev
    else
        sudo apt-get install --no-install-recommends -y python3-dev="$PYTHON_VERSION"
    fi
    sudo apt-get install --no-install-recommends -y python3-pip
    sudo ln -sf /usr/bin/pydoc3 /usr/bin/pydoc
    sudo ln -sf /usr/bin/python3 /usr/bin/python
    sudo ln -sf /usr/bin/python3-config /usr/bin/python-config
else
    echo "Unsupported OS: $OS"
    exit 1
fi

python -V
