#!/bin/bash
/etc/periodic/daily/defender.sh
/etc/periodic/daily/intune.sh
crond
lighttpd -f /etc/lighttpd/lighttpd.conf -D
