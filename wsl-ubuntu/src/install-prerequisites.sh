#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update --yes

sudo apt install --yes --no-install-recommends software-properties-common ansible
ansible-galaxy collection install amazon.aws
