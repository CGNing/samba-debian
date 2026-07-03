# syntax=docker/dockerfile:1

ARG DEBIAN_VERSION=stable

FROM debian:${DEBIAN_VERSION}-slim

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    tini \
    bash \
    samba \
    samba-client \
    smbldap-tools \
    tzdata \
    passwd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r smb && \
    rm -f /etc/samba/smb.conf

COPY --chmod=755 scripts/ /usr/bin/scripts/
COPY --chmod=664 smb.conf /etc/samba/smb.default

VOLUME /storage
EXPOSE 139 445

ENV NAME="Data"
ENV USER="samba"
ENV PASS="secret"

ENV UID=1000
ENV GID=1000
ENV RW=true

HEALTHCHECK --interval=60s --timeout=15s CMD smbclient --configfile=/etc/samba.conf -L \\localhost -U % -m SMB3

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/bin/scripts/samba.sh"]
