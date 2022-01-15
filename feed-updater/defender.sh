#!/bin/bash

# Variables
URL="https://download.microsoft.com/download/8/a/5/8a51eee5-cd02-431c-9d78-a58b7f77c070/mde-urls.xlsx"
HTTPD="/var/www/localhost/htdocs/feeds"

mkdir /tmp/defender/ -p
cd /tmp/defender
mkdir $HTTPD -p
wget $URL -O ./mde-urls.xlsx || echo "failure" > /var/www/localhost/htdocs/check.txt

if [[ "$(cat /var/www/localhost/htdocs/check.txt)" == "failure" ]]; then exit ; fi

xlsx2csv -a ./mde-urls.xlsx .

function pars_categories {
    value=$(echo $1 | tr -d '[:blank:]')
    
    case $value in
    "Common"*)
    echo "common"
    ;;

    "MicrosoftMonitoring"*)
    echo "microsoft-monitoring-agent"
    ;;

    "MicrosoftDefender"*)
    echo "microsoft-defender-for-endpoint"
    ;;

    "MU"*)
    echo "microsoft-update"
    ;;

    "Malware"*)
    echo "malware-submission"
    ;;

    "Reporting"*)
    echo "reporting-and-notifications"
    ;;

    *)
    echo $(echo $value | tr -cd '[:alnum:]._-')
    ;;

    esac

}

echo '{' > $HTTPD/microsoft-defender-for-endpoint.json
echo '  "description": "Microsoft Defender Endpoints (URL)",' >> $HTTPD/microsoft-defender-for-endpoint.json
echo '  "result": [' >> $HTTPD/microsoft-defender-for-endpoint.json

# Microsoft Defender for Endpoint URLs
while IFS="," read -r region category endpoint
do
    category=$(pars_categories "$category" | tr '[:upper:]' '[:lower:]')
    jq -n --arg type "URL" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "public" --arg url "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json
    
    if [[ "$endpoint" != *"*"* ]]
    then
        if [[ "$endpoint" != *"://"* ]]
        then
            jq -n --arg type "Domain" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "public" --arg domain "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json
        fi
        for ip in $(host -t a $endpoint | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "public" --arg ip "$ip" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json
        done
    fi
done < <(cut -d "," -f2,3,5 ./Microsoft\ Defender\ URLs.csv | tail -n +5)

# Microsoft Defender for Endpoint URLs US Gov
while IFS="," read -r region category endpoint
do
    category=$(pars_categories "$category" | tr '[:upper:]' '[:lower:]')
    jq -n --arg type "URL" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "government" --arg url "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json

    if [[ "$endpoint" != *"*"* ]]
    then
        if [[ "$endpoint" != *"://"* ]]
        then
            jq -n --arg type "Domain" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "governemnt" --arg domain "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json
        fi
        for ip in $(host -t a $endpoint | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "government" --arg ip "$ip" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json
        done
    fi

done < <(cut -d "," -f2,3,5 ./Microsoft\ Defender\ URLs\ -\ USGov.csv | tail -n +5)

# Security Center URLs
while IFS="," read -r endpoint
do
    jq -n --arg type "URL" --arg category "security-center" --arg serviceRegion "$region" --arg serviceArea "public" --arg url "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, url: $url}' | sed 's/https:\/\///' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json

    if [[ "$endpoint" != *"*"* ]]
    then
        if [[ "$endpoint" != *"://"* ]]
        then
            jq -n --arg type "Domain" --arg category "service-center" --arg serviceRegion "$region" --arg serviceArea "public" --arg domain "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json
        fi
        for ip in $(host -t a $endpoint | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "security-center" --arg serviceRegion "$region" --arg serviceArea "public" --arg ip "$ip" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json
        done
    fi

done < <(cut -d "," -f3 ./Security\ Center\ URLs.csv | tail -n +2)

# Security Center URLs US Gov
while IFS="," read -r region endpoint
do
    jq -n --arg type "URL" --arg category "security-center" --arg serviceRegion "$region" --arg serviceArea "government" --arg url "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, url: $url}' | sed 's/https:\/\///' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json

    if [[ "$endpoint" != *"*"* ]]
    then
        if [[ "$endpoint" != *"://"* ]]
        then
            jq -n --arg type "Domain" --arg category "service-center" --arg serviceRegion "$region" --arg serviceArea "government" --arg domain "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json
        fi
        for ip in $(host -t a $endpoint | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "security-center" --arg serviceRegion "$region" --arg serviceArea "government" --arg ip "$ip" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-defender-for-endpoint.json
        done
    fi

done < <(cut -d "," -f2,3 ./Security\ Center\ URLs\ -\ US\ Gov.csv | tail -n +2)

sed -i '$d' $HTTPD/microsoft-defender-for-endpoint.json
echo '    }' >> $HTTPD/microsoft-defender-for-endpoint.json
echo '  ]' >> $HTTPD/microsoft-defender-for-endpoint.json
echo '}' >> $HTTPD/microsoft-defender-for-endpoint.json

echo "=> Copy to legacy location"
mkdir "$HTTPD/defender" -p
cp "$HTTPD/microsoft-defender-for-endpoint.json" "$HTTPD/defender/feed.json"

rm -rf /tmp/defender

