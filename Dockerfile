FROM debian:latest

RUN mv /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak &&\
echo "Types: deb\n\
URIs: http://mirrors.tuna.tsinghua.edu.cn/debian\n\
Suites: bookworm bookworm-updates\n\
Components: main contrib non-free non-free-firmware\n\
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" > /etc/apt/sources.list.d/debian_tuna.sources &&\
    apt update -y

RUN set -eu && \
    apt install -y\
    tini \
    bash \
    samba \
    samba-client \
    smbldap-tools \
    tzdata \
    passwd && \
    addgroup --system smb && \
    rm -f /etc/samba/smb.conf

COPY --chmod=755 samba.sh /usr/bin/samba.sh
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

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/bin/samba.sh"]
