#!/usr/bin/env bash
docker_secret="/run/secrets/pass"
config="/etc/samba/smb.conf"

# Check if the secret file exists and if its size is greater than zero
if [ -s "$docker_secret" ]; then
    LDAP_PASSWORD=$(cat "$docker_secret")
fi

smbpasswd -w "$LDAP_PASSWORD"

# Set directory permissions
[ -d /run/samba/msg.lock ] && chmod -R 0755 /run/samba/msg.lock
[ -d /var/log/samba/cores ] && chmod -R 0700 /var/log/samba/cores
[ -d /var/cache/samba/msg.lock ] && chmod -R 0755 /var/cache/samba/msg.lock

# Start the Samba daemon with the following options:
#  --configfile: Location of the configuration file.
#  --foreground: Run in the foreground instead of daemonizing.
#  --debug-stdout: Send debug output to stdout.
#  --debuglevel=1: Set debug verbosity level to 1.
#  --no-process-group: Don't create a new process group for the daemon.
exec smbd --configfile="$config" --foreground --debug-stdout -d "${DEBUG_LEVEL:-1}" --no-process-group
