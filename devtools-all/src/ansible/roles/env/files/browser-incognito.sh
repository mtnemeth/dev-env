#!/usr/bin/env bash
powershell.exe -NoProfile -Command \
'Start-Process "msedge.exe" -ArgumentList "--inprivate", "'"$1"'"'
