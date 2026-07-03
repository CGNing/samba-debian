#!/usr/bin/env bash

wait_for_ldap() {
    local host=$1
    local port=$2
    local interval=$3

    echo "Waiting for OpenLDAP at ldap://$host:$port ..."
    while ! ldapsearch -x -H "ldap://$host:$port" -b "" -s base &>/dev/null; do
        sleep "$interval"
    done
    echo "OpenLDAP is ready."
}

wait_for_ldap "${LDAP_HOST:-localhost}" "${LDAP_PORT:-389}" "${LDAP_WAIT_INTERVAL:-1}"
