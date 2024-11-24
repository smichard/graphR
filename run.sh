#!/bin/bash

# Get the current UID assigned by OpenShift
CURRENT_UID=$(id -u)

# Replace the USERID_PLACEHOLDER in the config file with the actual UID
sed -i "s/USERID_PLACEHOLDER/$CURRENT_UID/" /home/shiny-app/shiny-server.conf

# Start Shiny Server using the custom configuration file
exec /usr/bin/shiny-server /home/shiny-app/shiny-server.conf
