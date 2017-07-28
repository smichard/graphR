FROM smichard/graphr_base
	
COPY ./graphr /srv/shiny-server/graphr

EXPOSE 3838

CMD [ "/bin/sh", "-c", "/usr/sbin/crond & /usr/bin/shiny-server" ]
