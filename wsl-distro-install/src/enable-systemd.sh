#!/usr/bin/env bash

sudo sed -i '$a[boot]\nsystemd=true\n' /etc/wsl.conf
