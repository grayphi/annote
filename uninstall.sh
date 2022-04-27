#!/usr/bin/env bash

INSTALL_NAME="annote"
INSTALLED_BIN="$(which "$INSTALL_NAME" 2> /dev/null)"

if [ -n "$INSTALLED_BIN" ]; then
    rm -f "$INSTALLED_BIN"
    HOME_DIR="$(realpath ~)/.annote"
    CONF_FILE="$HOME_DIR/annote.config"
    VIMRC_FILE="$HOME_DIR/vimrc"

    if [ -f "$VIMRC_FILE" ]; then
        rm $VIMRC_FILE
    fi

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
