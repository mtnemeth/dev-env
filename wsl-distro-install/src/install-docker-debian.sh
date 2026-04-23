#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

## Official Docker install steps from https://docs.docker.com/engine/install/debian/
## with slight modifications (--yes flag for apt install)

# Add Docker's official GPG key:
sudo apt update
sudo apt install --yes ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update --yes

sudo apt install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

####### End of official instal steps

sudo usermod -a -G docker $(whoami)
