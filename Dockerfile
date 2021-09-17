FROM alpine:latest

LABEL org.opencontainers.image.authors="dev@pierewoehl.de"
LABEL org.opencontainers.image.source="https://github.com/pierew/intelligencefeeds.azurewebsites.net"

ENV PORT 80
EXPOSE 80

RUN apk add --no-cache python3 py3-pip lighttpd bash
RUN pip install xlsx2csv

COPY config/lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY config/dir-listing.css /var/www/localhost/htdocs/dir-listing.css

COPY feed-updater/defender-atp.sh /etc/periodic/15min/defender-atp.sh
RUN chmod +x /etc/periodic/15min/defender-atp.sh

COPY entrypoint.sh entrypoint.sh
CMD ["/bin/bash","/entrypoint.sh"]

