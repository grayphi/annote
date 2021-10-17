#!/usr/bin/env bash

INSTALL_NAME="annote"
INSTALLED_PATH="$(which "$INSTALL_NAME" 2> /dev/null)"

if [ -n "$INSTALLED_PATH" ]; then
    rm -f $INSTALLED_PATH/$INSTALL_NAME
    HOME_DIR="$(realpath ~)/.annote"
    CONF_FILE="$HOME_DIR/annote.config"
    if [ -d "$HOME_DIR" ] && [ -f "$CONF_FILE" ]; then
        DB_DIR="$(cat "$CONF_FILE"  | sed -e 's/^\s\+//' | grep "^db_loc" | cut -d= -f2- | sed -e 's/^\s\+//' -e 's/\s\+$//')"
        rm -f "$CONF_FILE"
        rmdir "$HOME_DIR" 2> /dev/null
        if [ -n "$DB_DIR" ]; then
            echo "db is configured at '$DB_DIR', remove if not required."
        fi
        echo "Done uninstalling."
    fi
else
    echo "'$INSTALL_NAME' is not installed, or is not in your '\$PATH' locations."
fi
