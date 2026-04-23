#!/usr/bin/env bash
set -e

script_root="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

cd "${script_root}"

if [ -z "${dt_user}" ]; then
    read -p "Enter your name (for git):" dt_user
fi

if [ -z "${dt_email}" ]; then
    read -p "Enter your email address (for git):" dt_email
fi

echo "Username: ${dt_user}"
echo "Email:    ${dt_email}"

echo "Making sure pre-requisites are installed..."

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update --yes

sudo apt install --yes --no-install-recommends ansible #software-properties-common
ansible-galaxy collection install amazon.aws


echo "Running Ansible playbook..."

cd ./src/ansible

ansible-playbook -i inventory.yml main.yml --extra-vars 'email_address="'"${dt_email}"'" user_name="'"${dt_user}"'"'
