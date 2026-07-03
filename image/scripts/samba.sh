#!/usr/bin/env bash
set -Eeuo pipefail

config="/etc/samba/smb.conf"
secret="/run/secrets/pass"

# Check if config file is not a directory
if [ -f "$config" ]; then
    echo "Using provided configuration file"
elif [ -d "$config" ]; then
    echo "$config should not be a directory"
    exit 1
else
    echo "config file not found"
    exit 1
fi

#获取NETBIOS名称
NETBIOS_NAME=$(testparm -s "${config}" --parameter-name="netbios name" 2>/dev/null)
if [[ -n "${NETBIOS_NAME}" ]]; then
    echo "NETBIOS_NAME: ${NETBIOS_NAME}"
else
    echo "ERROR: Failed to retrieve NETBIOS_NAME from smb.conf" >&2
    exit 1
fi

# Check if the secret file exists and if its size is greater than zero
if [ -s "$secret" ]; then
    LDAP_BIND_PASSWORD=$(cat "$secret")
fi
#写入LDAP密码到samba
if ! smbpasswd -w "${LDAP_BIND_PASSWORD}"; then
    echo "ERROR: Failed to set LDAP bind password in Samba" >&2
    exit 1
fi

#获取SID
if ! SID=$(ldapsearch -x -H "ldap://${LDAP_HOST}:${LDAP_PORT}/" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PASSWORD}" \
    -b "${LDAP_BASE_DN}" \
    "(&(objectClass=sambaDomain)(sambaDomainName=${NETBIOS_NAME}))" sambaSID \
    | awk '/^sambaSID:/ {print $2}'); then
    echo "ERROR: Failed to retrieve sambaSID from LDAP" >&2
    exit 1
fi
# 设置SID
if [[ -n "${SID}" ]]; then
    net setlocalsid "${SID}"
    echo "Set local SID to ${SID}"
else
    echo "Get empty SID from LDAP"
fi

# Set directory permissions
[ -d /run/samba/msg.lock ] && chmod -R 0755 /run/samba/msg.lock || :
[ -d /var/log/samba/cores ] && chmod -R 0700 /var/log/samba/cores || :
[ -d /var/cache/samba/msg.lock ] && chmod -R 0755 /var/cache/samba/msg.lock || :

winbindd --configfile="${config}" -F --no-process-group --debug-stdout -d "${DEBUG_LEVEL:-1}" &
WINBIND_PID=$!

# Start the Samba daemon with the following options:
#  --configfile: Location of the configuration file.
#  --foreground: Run in the foreground instead of daemonizing.
#  --debug-stdout: Send debug output to stdout.
#  --debuglevel=1: Set debug verbosity level to 1.
#  --no-process-group: Don't create a new process group for the daemon.
exec smbd --configfile="${config}" --foreground --no-process-group --debug-stdout -d "${DEBUG_LEVEL:-1}"
SMBD_PID=$!

wait -n "$WINBIND_PID" "$SMBD_PID"
exit $?
