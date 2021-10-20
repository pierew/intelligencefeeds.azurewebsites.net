#!/bin/bash

# Variables
URL="https://download.microsoft.com/download/8/a/5/8a51eee5-cd02-431c-9d78-a58b7f77c070/mde-urls.xlsx"
HTTPD="/var/www/localhost/htdocs/feeds/defender"

mkdir /tmp/defender/ -p
cd /tmp/defender
rm -rf $HTTPD/government/ $HTTPD/region-* 
mkdir $HTTPD -p
wget $URL -O ./mde-urls.xlsx
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
    echo $value
    ;;

    esac

}

echo '{' > $HTTPD/feed.json
echo '  "description": "Microsoft Defender Endpoints (URL)",' >> $HTTPD/feed.json
echo '  "result": [' >> $HTTPD/feed.json

# Microsoft Defender for Endpoint URLs
while IFS="," read -r region category endpoint
do
    category=$(pars_categories "$category" | tr '[:upper:]' '[:lower:]')
    FOLDERNAME="region-$(echo $region | tr '[:upper:]' '[:lower:]' | tr -d '[:blank:]')"
    mkdir $HTTPD/$FOLDERNAME -p
    echo $endpoint >> "$HTTPD/$FOLDERNAME/$category".txt
    jq -n --arg type "URL" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "public" --arg url "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json

    if [[ "$endpoint" != *"*"* ]]
    then
        for ip in $(host -t a $endpoint | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "public" --arg ip "$ip" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        done
    fi
done < <(cut -d "," -f2,3,5 ./Microsoft\ Defender\ URLs.csv | tail -n +5)

# Microsoft Defender for Endpoint URLs US Gov
while IFS="," read -r region category endpoint
do
    category=$(pars_categories "$category" | tr '[:upper:]' '[:lower:]')
    FOLDERNAME="government/$(echo $region | tr '[:upper:]' '[:lower:]' | tr -d '[:blank:]')"
    mkdir $HTTPD/$FOLDERNAME -p
    echo $endpoint >> "$HTTPD/$FOLDERNAME/$category".txt
    jq -n --arg type "URL" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "government" --arg url "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json

    if [[ "$endpoint" != *"*"* ]]
    then
        for ip in $(host -t a $endpoint | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "$category" --arg serviceRegion "$region" --arg serviceArea "government" --arg ip "$ip" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        done
    fi

done < <(cut -d "," -f2,3,5 ./Microsoft\ Defender\ URLs\ -\ USGov.csv | tail -n +5)

# Security Center URLs
while IFS="," read -r endpoint
do
    FOLDERNAME="region-ww"
    mkdir $HTTPD/$FOLDERNAME -p
    echo $endpoint | sed 's/https:\/\///' >> "$HTTPD/$FOLDERNAME/security-center.txt"
    jq -n --arg type "URL" --arg category "security-center" --arg serviceRegion "$region" --arg serviceArea "public" --arg url "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, url: $url}' | sed 's/https:\/\///' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json

    if [[ "$endpoint" != *"*"* ]]
    then
        for ip in $(host -t a $endpoint | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "security-center" --arg serviceRegion "$region" --arg serviceArea "public" --arg ip "$ip" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        done
    fi

done < <(cut -d "," -f3 ./Security\ Center\ URLs.csv | tail -n +2)

# Security Center URLs US Gov
while IFS="," read -r region endpoint
do
    FOLDERNAME="government/$(echo $region | tr '[:upper:]' '[:lower:]' | tr -d '[:blank:]')"
    mkdir $HTTPD/$FOLDERNAME -p
    echo $endpoint | sed 's/https:\/\///' >> "$HTTPD/$FOLDERNAME/security-center.txt"
    jq -n --arg type "URL" --arg category "security-center" --arg serviceRegion "$region" --arg serviceArea "government" --arg url "$endpoint" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, url: $url}' | sed 's/https:\/\///' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json

    if [[ "$endpoint" != *"*"* ]]
    then
        for ip in $(host -t a $endpoint | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "security-center" --arg serviceRegion "$region" --arg serviceArea "government" --arg ip "$ip" '{type: $type, category: $category, serviceRegion: $serviceRegion, serviceArea: $serviceArea, ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        done
    fi

done < <(cut -d "," -f2,3 ./Security\ Center\ URLs\ -\ US\ Gov.csv | tail -n +2)

sed -i '$d' $HTTPD/feed.json
echo '    }' >> $HTTPD/feed.json
echo '  ]' >> $HTTPD/feed.json
echo '}' >> $HTTPD/feed.json

rm -rf /tmp/defender

