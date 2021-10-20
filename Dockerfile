FROM alpine:latest

LABEL org.opencontainers.image.authors="dev@pierewoehl.de"
LABEL org.opencontainers.image.source="https://github.com/pierew/serviceendpoints.azurewebsites.net"

ENV PORT 80
EXPOSE 80

RUN apk add --no-cache python3 py3-pip lighttpd bash git jq
RUN pip install xlsx2csv

RUN git clone https://github.com/tomroy/mdtable2csv.git /opt/mdtable2csv
RUN pip install -r /opt/mdtable2csv/requirements.txt
RUN ln -s /usr/bin/python3 /usr/local/bin/python

COPY config/lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY config/mime-types.conf /etc/lighttpd/mime-types.conf
COPY config/dir-listing.css /var/www/localhost/htdocs/dir-listing.css

COPY feed-updater/defender.sh /etc/periodic/15min/defender.sh
COPY feed-updater/intune.sh /etc/periodic/15min/intune.sh
RUN chmod +x /etc/periodic/15min/defender.sh
RUN chmod +x /etc/periodic/15min/intune.sh

RUN echo "ok" > /var/www/localhost/htdocs/check.txt

COPY entrypoint.sh entrypoint.sh
CMD ["/bin/bash","/entrypoint.sh"]

