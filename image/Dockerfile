# syntax=docker/dockerfile:1

ARG DEBIAN_VERSION=stable

FROM debian:${DEBIAN_VERSION}-slim

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    tini \
    samba \
    samba-client \
    smbldap-tools \
    winbind \
    libnss-winbind \
    ldap-utils \
    tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r samba && \
    rm -f /etc/samba/smb.conf

COPY --chmod=755 scripts/ /usr/bin/scripts/
COPY --chmod=664 smb.conf /etc/samba/smb.conf

VOLUME /storage
EXPOSE 139 445

ENV NAME="Data"
ENV USER="samba"
ENV PASS="secret"

ENV UID=1000
ENV GID=1000
ENV RW=true

ENV LDAP_HOST="openldap"
ENV LDAP_PORT="389"
ENV LDAP_BIND_DN="cn=admin,dc=example,dc=org"
ENV LDAP_BIND_PASSWORD="adminpassword"
ENV LDAP_BASE_DN="dc=example,dc=com"
ENV LDAP_WAIT_INTERVAL=1

HEALTHCHECK --start-period=30s --interval=60s --timeout=15s CMD smbclient --configfile=/etc/smb.conf -L \\localhost -U % -m SMB3

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/bin/scripts/entrypoint.sh"]
