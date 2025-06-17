# Ansible playbook to install all dev tools on WSL distro

## Pre-requities

1. [Install Ubuntu WSL distro](../wsl/README.md)

## Config

Optionalliy, you may want to
- edit `src/ansible/main.yml` and comment out certain roles if you don't need them
- edit `src/ansible/group_vars/all.yml` to configure git and browser location on the host OS
- edit `src/ansible/roles/snowflake/vars/main.yml` to configure Snowflake CLI and SnowSQL versions

## Run playbook to install tools

## Option one - specify parameters before running the install

```Bash
dt_user="Your Name" dt_email="your.name@your.domain" ./install.sh
```

## Option two - enter values when propmted

```Bash
./install.sh
```

