#!/usr/bin/env bash

INSTALL_LOC="$(realpath ~)/.local/bin"
INSTALL_NAME="annote"

if [ -n "$1" ]; then
    INSTALL_LOC="$1"
fi

mkdir -p $INSTALL_LOC
cp ./annote.sh $INSTALL_LOC/$INSTALL_NAME
chmod +x $INSTALL_LOC/$INSTALL_NAME

bash $INSTALL_LOC/$INSTALL_NAME -C --import ./annote.config

echo "Done installing, make sure '$INSTALL_LOC' is configured in your \$PATH variable."

