#!/usr/bin/env bash

set -e

on_exit() {
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "Install failed."
  else
    echo "Install completed."
  fi
}

trap on_exit EXIT

curl -fsSLo /usr/local/bin/ssm-connect \
https://raw.githubusercontent.com/mtnemeth/dev-env/refs/heads/main/aws/ssm-connect/ssm-connect

chmod 755 /usr/local/bin/ssm-connect
