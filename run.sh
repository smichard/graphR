#!/bin/bash

# Get the current UID assigned to the process
CURRENT_UID=$(id -u)

# Check if the current UID is 0 (root)
if [ "$CURRENT_UID" -eq 0 ]; then
    # If running as root, use the 'shiny' user
    sed -i "s/USERID_PLACEHOLDER/shiny/" /home/shiny-app/shiny-server.conf
else
    # Otherwise, use the current UID
    sed -i "s/USERID_PLACEHOLDER/$CURRENT_UID/" /home/shiny-app/shiny-server.conf
fi

# Start Shiny Server using the custom configuration file
exec /usr/bin/shiny-server /home/shiny-app/shiny-server.conf
