#!/usr/bin/env bash
set -Eeuo pipefail

smbldap-config
smbpasswd -w "${LDAP_BIND_PASSWORD}"
smbldap-populate
smbldap-useradd -a ${USER}
