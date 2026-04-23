#!/bin/bash

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <group> <user> <password>"
    exit 1
fi

NEW_GROUP="${1}"
NEW_USER="${2}"
NEW_PASSWORD="${3}"

addgroup -u 1000 "${NEW_GROUP}"

useradd -u 1000 \
--create-home \
--shell /usr/bin/bash \
--user-group --groups adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev,"${NEW_GROUP}" \
"${NEW_USER}"

(echo "${NEW_PASSWORD}"; echo "${NEW_PASSWORD}") | passwd "${NEW_USER}"

cat << EOF > /etc/wsl.conf
[user]
default=${NEW_USER}
EOF

echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
