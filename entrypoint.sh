#!/bin/bash
echo "=> Starting Webserver"
lighttpd -f /etc/lighttpd/lighttpd.conf -D &

cd /app/scripts

echo "=> Initialization"
for script in *.sh
do
    /bin/bash "$script" &
done

echo "=> Entering Update Loop"
while true 
do
    minute=$(date +%M)
    if [[ $minute == "00" ]]
    then
        echo "=> Performing Update"
        for script in *.sh
        do
            /bin/bash "$script" &
        done
    fi
    sleep 60
done

