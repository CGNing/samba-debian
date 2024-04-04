#!/usr/bin/env bash
set -Eeuo pipefail

# Set variables for group and share directory
group="smb"
share="/storage"

# Create shared directory
mkdir -p "$share" || { echo "Failed to create directory $share"; exit 1; }

# Copy config file template
rm -f /etc/samba/smb.custom
cp /etc/samba/smb.conf /etc/samba/smb.custom

# Check if the smb group exists, if not, create it
if ! getent group "$group" &>/dev/null; then
    groupadd "$group" || { echo "Failed to create group $group"; exit 1; }
fi

# Check if the user already exists, if not, create it
if ! id "$USER" &>/dev/null; then
    adduser -S -D -H -h /tmp -s /sbin/nologin -G "$group" -g 'Samba User' "$USER" || { echo "Failed to create user $USER"; exit 1; }
fi

# Get the current user and group IDs
OldUID=$(id -u "$USER")
OldGID=$(getent group "$group" | cut -d: -f3)

# Change the UID and GID of the user and group if necessary
if [[ "$OldUID" != "$UID" ]]; then
    usermod -o -u "$UID" "$USER" || { echo "Failed to change UID for $USER"; exit 1; }
fi

if [[ "$OldGID" != "$GID" ]]; then
    groupmod -o -g "$GID" "$group" || { echo "Failed to change GID for group $group"; exit 1; }
fi

# Change Samba password
echo -e "$PASS\n$PASS" | smbpasswd -a -s "$USER" || { echo "Failed to change Samba password for $USER"; exit 1; }

# Update force user and force group in smb.conf
sed -i "s/^\(\s*\)force user =.*/\1force user = $USER/" "/etc/samba/smb.custom"
sed -i "s/^\(\s*\)force group =.*/\1force group = $group/" "/etc/samba/smb.custom"

# Verify if the RW variable is equal to false (indicating read-only mode) 
if [[ "$RW" == [Ff0]* ]]; then

    # Adjust settings in smb.conf to set share to read-only
    sed -i "s/^\(\s*\)writable =.*/\1writable = no/" "/etc/samba/smb.custom"
    sed -i "s/^\(\s*\)read only =.*/\1read only = yes/" "/etc/samba/smb.custom"

else

    # Set permissions for share directory if new (empty), leave untouched if otherwise
    if [ -z "$(ls -A "$share")" ]; then
      chmod 0770 "$share" || { echo "Failed to set permissions for directory $share"; exit 1; }
      chown "$USER:$group" "$share" || { echo "Failed to set ownership for directory $share"; exit 1; }
    fi

fi

# Start the Samba daemon with the following options:
#  --foreground: Run in the foreground instead of daemonizing.
#  --debug-stdout: Send debug output to stdout.
#  --debuglevel=1: Set debug verbosity level to 1.
#  --no-process-group: Don't create a new process group for the daemon.
exec smbd --configfile=/etc/samba/smb.custom --foreground --debug-stdout --debuglevel=1 --no-process-group
