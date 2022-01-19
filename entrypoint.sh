#!/bin/bash
echo "=> Starting Webserver"
lighttpd -f /etc/lighttpd/lighttpd.conf -D &

cd /app/scripts

while true 
do
    echo "=> Performing Update"
    for script in *.sh
    do
        /bin/bash "$script" &
    done
    
    echo "=> Waiting 60 minutes for the next run..."
    sleep 3600
done

