FROM eu.gcr.io/storied-network-317810/graphr-base

# Copying source code and cron job
COPY ./graphr /srv/shiny-server/graphr
COPY ./shiny-server.conf /etc/shiny-server/shiny-server.conf
COPY cleaning_job.sh /cleaning_job.sh
COPY crontab_entry.txt /etc/cron.d/cleaning-job

RUN chmod +x /cleaning_job.sh && chmod 0644 /etc/cron.d/cleaning-job && touch /var/log/cron.log

EXPOSE 3838

CMD [ "/bin/sh", "-c", "/usr/sbin/crond & /usr/bin/shiny-server" ]
