#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(dirname "$0")

"$SCRIPT_DIR/wait-ldap.sh"
exec "$SCRIPT_DIR/samba.sh"

# TODO: use krb5 for authentication
# TODO: ldap parameters replace
# TODO: samba-ldap-init
