#!/bin/bash

# Variables
URL="https://raw.githubusercontent.com/MicrosoftDocs/IntuneDocs/master/intune/fundamentals/intune-endpoints.md"
URL2="https://raw.githubusercontent.com/MicrosoftDocs/memdocs/master/memdocs/configmgr/core/plan-design/network/includes/internet-endpoints-cloud-services.md"
HTTPD="/var/www/localhost/htdocs/feeds"

mkdir /tmp/intune/ -p
mkdir $HTTPD -p
cd /tmp/intune

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

cat ./url-management.txt | tr " " "\n" | sed '/^$/d' > ./url-management-filtered.txt
cat ./ipv4-management.txt | tr " " "\n" | sed '/^$/d' > ./ipv4-management-filtered.txt

# Generate Script lists
while IFS="," read -r azure_storage_unit storage_name cdn
do
    echo $cdn >> ./url-powershell_and_win32.txt
done < <(tail -n +2 intune-scripts.csv)
cat ./url-powershell_and_win32.txt | tr " " "\n" | sed '/^$/d' > ./powershell.txt

# Generate CMG List
cat ./intune-endpoints-cmg.md | grep "Azure AD endpoints" | cut -d'|' -f3 | sed -e 's/<br>/ /g' | sed -e 's/`/ /g' | cut -d" " -f3 > ./cmg.txt
cat ./intune-endpoints-cmg.md | grep "Azure AD endpoints" | cut -d'|' -f3 | sed -e 's/<br>/ /g' | sed -e 's/`/ /g' | cut -d" " -f6 >> ./cmg.txt
cat ./intune-endpoints-cmg.md | grep "Azure AD endpoints" | cut -d'|' -f3 | sed -e 's/<br>/ /g' | sed -e 's/`/ /g' | cut -d" " -f9 >> ./cmg.txt
cat ./intune-endpoints-cmg.md | grep "Azure AD endpoints" | cut -d'|' -f4 | sed -e 's/<br>/ /g' | sed -e 's/`/ /g' | cut -d" " -f3 >> ./cmg.txt

# Generate JSONs

echo '{' > $HTTPD/microsoft-endpoint-manager.json
echo '  "description": "Microsoft Intune Endpoints (URL and IPv4)",' >> $HTTPD/microsoft-endpoint-manager.json
echo '  "result": [' >> $HTTPD/microsoft-endpoint-manager.json

for item in $(cat ./url-management-filtered.txt)
do
    jq -n --arg type "URL" --arg category "management" --arg url "$item" '{type: $type, category: $category , url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json

    if [[ "$item" != *"*"* ]]
    then
        jq -n --arg type "Domain" --arg category "management" --arg domain "$item" '{type: $type, category: $category , domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json
        for ip in $(host -t a $item | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "management" --arg ip "$ip" '{type: $type, category: $category , ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json
        done
    fi
done

for item in $(cat ./powershell.txt)
do
    jq -n --arg type "URL" --arg category "powershell" --arg url "$item" '{type: $type, category: $category , url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json
    
    if [[ "$item" != *"*"* ]]
    then
        jq -n --arg type "Domain" --arg category "powershell" --arg domain "$item" '{type: $type, category: $category , domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json
        for ip in $(host -t a $item | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "powershell" --arg ip "$ip" '{type: $type, category: $category , ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json
        done
    fi
done

for item in $(cat ./ipv4-management-filtered.txt)
do
    jq -n --arg type "IPv4" --arg category "management" --arg ip "$item" '{type: $type, category: $category , ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json
done

for item in $(cat ./cmg.txt)
do
    jq -n --arg type "URL" --arg category "cloud-management-gateway" --arg url "$item" '{type: $type, category: $category , url: $url}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json
    
    if [[ "$item" != *"*"* ]]
    then
        jq -n --arg type "Domain" --arg category "cloud-management-gateway" --arg domain "$item" '{type: $type, category: $category , domain: $domain}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json
        for ip in $(host -t a $item | grep "has address" | cut -d" " -f4)
        do
            jq -n --arg type "IPv4" --arg category "cloud-management-gateway" --arg ip "$ip" '{type: $type, category: $category , ip: $ip}' | sed 's/}/},/' | sed 's/^/    /' >> $HTTPD/microsoft-endpoint-manager.json
        done
    fi
done

sed -i '$d' $HTTPD/microsoft-endpoint-manager.json
echo '    }' >> $HTTPD/microsoft-endpoint-manager.json
echo '  ]' >> $HTTPD/microsoft-endpoint-manager.json
echo '}' >> $HTTPD/microsoft-endpoint-manager.json

echo "=> Copy to legacy location"
mkdir "$HTTPD/intune" -p
cp "$HTTPD/microsoft-endpoint-manager.json" "$HTTPD/intune/feed.json"

rm -rf /tmp/intune