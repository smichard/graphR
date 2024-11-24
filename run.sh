#!/bin/bash

# Get the current UID assigned by OpenShift
CURRENT_UID=$(id -u)

# Replace the USERID_PLACEHOLDER in shiny-server.conf with the actual UID
sed -i "s/USERID_PLACEHOLDER/$CURRENT_UID/" /etc/shiny-server/shiny-server.conf

# Start Shiny Server
exec /usr/bin/shiny-server