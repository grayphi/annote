#!/usr/bin/env bash

INSTALL_NAME="annote"
INSTALLED_PATH="$(which "$INSTALL_NAME" 2> /dev/null)"

if [ -n "$INSTALLED_PATH" ]; then
    cp ./annote.sh $INSTALLED_PATH/$INSTALL_NAME
    chmod +x $INSTALLED_PATH/$INSTALL_NAME
    echo "Done upgrading."
else
    echo "'$INSTALL_NAME' is not installed, or is not in your '\$PATH' locations, install first before trying upgrade."
fi
