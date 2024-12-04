#!/bin/bash

# Check if domain argument is provided
while getopts "u:" option; do
    case $option in
        u) domain=$OPTARG ;;
        *) echo "Usage: $0 -u <domain>"; exit 1 ;;
    esac
done

if [ -z "$domain" ]; then
    echo "Usage: $0 -u <domain>"
    exit 1
fi

# Step 1: Create directory for the domain and find subdomains
mkdir -p "$domain"
echo "[+] Step 1: Running spyhunt.py to find subdomains for $domain..."
python3 ~/tools/spyhunt/spyhunt.py -s "$domain" --save "$domain/subdomains"

# Step 2: Check for live subdomains using httpx-toolkit
echo "[+] Step 2: Checking for live subdomains using httpx-toolkit..."
httpx-toolkit -l "$domain/subdomains" -ports 80,443,8000,8080,8888 -threads 200 -o "$domain/alivesubs"

# Remove http:// and https:// from live subdomains and save them as validdomains
echo "[+] Cleaning up alivesubs and saving to validdomains..."
awk -F'//' '{print $2}' "$domain/alivesubs" > "$domain/validdomains"

# Step 3: Process each valid domain with the given oneliner
echo "[+] Running XSS checks for each valid domain..."
while read -r validdomain; do
    echo "$validdomain" | gau | gf xss | uro | Gxss -p Rxss | dalfox pipe > "$domain/${validdomain}_xss_errors.txt"
    echo "[+] XSS results saved for $validdomain in ${validdomain}_xss_errors.txt"
done < "$domain/validdomains"

echo "[+] All tasks completed for $domain."
