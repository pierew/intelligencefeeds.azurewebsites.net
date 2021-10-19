FROM alpine:latest

LABEL org.opencontainers.image.authors="dev@pierewoehl.de"
LABEL org.opencontainers.image.source="https://github.com/pierew/intelligencefeeds.azurewebsites.net"

ENV PORT 80
EXPOSE 80

RUN apk add --no-cache python3 py3-pip lighttpd bash git
RUN pip install xlsx2csv

RUN git clone https://github.com/tomroy/mdtable2csv.git /opt/mdtable2csv
RUN pip install -r /opt/mdtable2csv/requirements.txt
RUN ln -s /usr/bin/python3 /usr/local/bin/python

COPY config/lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY config/dir-listing.css /var/www/localhost/htdocs/dir-listing.css

COPY feed-updater/defender-atp.sh /etc/periodic/15min/defender-atp.sh
COPY feed-updater/intune.sh /etc/periodic/15min/intune.sh
RUN chmod +x /etc/periodic/15min/defender-atp.sh
RUN chmod +x /etc/periodic/15min/intune.sh

RUN echo "ok" > /var/www/localhost/htdocs/check

COPY entrypoint.sh entrypoint.sh
CMD ["/bin/bash","/entrypoint.sh"]

