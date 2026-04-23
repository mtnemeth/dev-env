#!/usr/bin/env bash

script_root="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd "${script_root}"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "${ID}" == "ubuntu" ]]; then
        ./install-docker-ubuntu.sh
    elif [[ "${ID}" == "debian" ]]; then
        ./install-docker-debian.sh
    else
        echo "Unsupported Linux distribution: ${ID}"
        exit 1
    fi
else
    echo "Cannot determine Linux distribution. /etc/os-release not found."
    exit 1
fi
