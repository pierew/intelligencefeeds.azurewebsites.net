#!/bin/bash

# Variables
URL="https://raw.githubusercontent.com/MicrosoftDocs/IntuneDocs/master/intune/fundamentals/intune-endpoints.md"
URL2="https://raw.githubusercontent.com/MicrosoftDocs/memdocs/master/memdocs/configmgr/core/plan-design/network/includes/internet-endpoints-cloud-services.md"
HTTPD="/var/www/localhost/htdocs/feeds/intune"

mkdir /tmp/intune/ -p
cd /tmp/intune
rm -rf $HTTPD/
mkdir $HTTPD/url -p
mkdir $HTTPD/ipv4 -p

wget $URL -O ./intune-endpoints.md || echo "failure" > /var/www/localhost/htdocs/check.txt
wget $URL2 -O ./intune-endpoints-cmg.md || echo "failure" > /var/www/localhost/htdocs/check.txt

if [[ "$(cat /var/www/localhost/htdocs/check.txt)" == "failure" ]]; then exit ; fi

# Split File into Categories
cat ./intune-endpoints.md | awk '/client accesses/,/## Network requirements/' | grep -v "client accesses" | grep -v "## Network requirements" > ./intune-management-endpoints.md
cat ./intune-endpoints.md | awk '/currently resides/,/## Windows Push/' | grep -v "currently resides" | grep -v "## Windows Push" > ./intune-scripts.md

sed -e 's/<br>/ /g' intune-scripts.md -i
sed -e 's/<br>/ /g' intune-management-endpoints.md -i

/opt/mdtable2csv/mdtable2csv intune-scripts.md 
/opt/mdtable2csv/mdtable2csv intune-management-endpoints.md 

# Generate Management lists
while IFS="," read -r domain ip_address
do
    echo $domain >> ./url-management.txt
    echo $ip_address >> ./ipv4-management.txt
    
done < <(tail -n +2 intune-management-endpoints.csv)

cat ./url-management.txt | tr " " "\n" | sed '/^$/d' > $HTTPD/url/management.txt
cat ./ipv4-management.txt | tr " " "\n" | sed '/^$/d' > $HTTPD/ipv4/management.txt

# Generate Script lists
while IFS="," read -r azure_storage_unit storage_name cdn
do
    echo $cdn >> ./url-powershell_and_win32.txt
done < <(tail -n +2 intune-scripts.csv)
cat ./url-powershell_and_win32.txt | tr " " "\n" | sed '/^$/d' > /$HTTPD/url/powershell.txt

# Generate CMG List
cat ./intune-endpoints-cmg.md | grep "Azure AD endpoints" | cut -d'|' -f3 | sed -e 's/<br>/ /g' | sed -e 's/`/ /g' | cut -d" " -f3 > $HTTPD/url/cmg.txt
cat ./intune-endpoints-cmg.md | grep "Azure AD endpoints" | cut -d'|' -f3 | sed -e 's/<br>/ /g' | sed -e 's/`/ /g' | cut -d" " -f6 >> $HTTPD/url/cmg.txt
cat ./intune-endpoints-cmg.md | grep "Azure AD endpoints" | cut -d'|' -f3 | sed -e 's/<br>/ /g' | sed -e 's/`/ /g' | cut -d" " -f9 >> $HTTPD/url/cmg.txt
cat ./intune-endpoints-cmg.md | grep "Azure AD endpoints" | cut -d'|' -f4 | sed -e 's/<br>/ /g' | sed -e 's/`/ /g' | cut -d" " -f3 >> $HTTPD/url/cmg.txt

# Generate JSONs

echo '{' > $HTTPD/feed.json
echo '  "description": "Microsoft Intune Endpoints (URL and IPv4)",' >> $HTTPD/feed.json
echo '  "result": [' >> $HTTPD/feed.json

for item in $(cat $HTTPD/url/management.txt)
do
    jq -n --arg type "URL" --arg category "management" --arg url "$item" '{type: $type, category: $category , url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json

    if [[ "$item" != *"*"* ]]
    then
        jq -n --arg type "Domain" --arg category "management" --arg domain "$item" '{type: $type, category: $category , domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        for ip in $(host -t a $item | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "management" --arg ip "$ip" '{type: $type, category: $category , ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        done
    fi
done

for item in $(cat $HTTPD/url/powershell.txt)
do
    jq -n --arg type "URL" --arg category "powershell" --arg url "$item" '{type: $type, category: $category , url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
    
    if [[ "$item" != *"*"* ]]
    then
        jq -n --arg type "Domain" --arg category "powershell" --arg domain "$item" '{type: $type, category: $category , domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        for ip in $(host -t a $item | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "powershell" --arg ip "$ip" '{type: $type, category: $category , ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        done
    fi
done

for item in $(cat $HTTPD/ipv4/management.txt)
do
    jq -n --arg type "IPv4" --arg category "management" --arg ip "$item" '{type: $type, category: $category , ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
done

for item in $(cat $HTTPD/url/cmg.txt)
do
    jq -n --arg type "URL" --arg category "cloud-management-gateway" --arg url "$item" '{type: $type, category: $category , url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
    
    if [[ "$item" != *"*"* ]]
    then
        jq -n --arg type "Domain" --arg category "cloud-management-gateway" --arg domain "$item" '{type: $type, category: $category , domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        for ip in $(host -t a $item | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "cloud-management-gateway" --arg ip "$ip" '{type: $type, category: $category , ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/feed.json
        done
    fi
done

sed -i '$d' $HTTPD/feed.json
echo '    }' >> $HTTPD/feed.json
echo '  ]' >> $HTTPD/feed.json
echo '}' >> $HTTPD/feed.json

rm -rf /tmp/intune