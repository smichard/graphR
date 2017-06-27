#! /bin/bash
find /srv/shiny-server/graphr/www -name "*.pdf" -type f -mmin +5 -delete
