#!/bin/bash
/etc/periodic/15min/defender-atp.sh
/etc/periodic/15min/intune.sh
lighttpd -f /etc/lighttpd/lighttpd.conf -D
