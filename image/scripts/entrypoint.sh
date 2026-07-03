#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(dirname "$0")

"$SCRIPT_DIR/wait-ldap.sh"
exec "$SCRIPT_DIR/samba.sh"
