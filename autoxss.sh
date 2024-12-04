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
echo "[+] Step 1: Finding subdomains for $domain using assetfinder and subfinder..."
assetfinder -subs-only "$domain" | uniq | sort > "$domain/subdomains_assetfinder"
subfinder -d "$domain" -silent > "$domain/subdomains_subfinder"

# Combine results and remove duplicates
cat "$domain/subdomains_assetfinder" "$domain/subdomains_subfinder" | sort -u > "$domain/subdomains"
rm "$domain/subdomains_assetfinder" "$domain/subdomains_subfinder"
echo "[+] Subdomains saved to $domain/subdomains."

# Step 2: Check for live subdomains using httpx-toolkit
echo "[+] Step 2: Checking for live subdomains using httpx-toolkit..."
httpx-toolkit -l "$domain/subdomains" -ports 80,443,8000,8080,8888 -threads 200 -o "$domain/alivesubs"

# Remove http:// and https:// from live subdomains, remove duplicates, and save them as validdomains
echo "[+] Cleaning up alivesubs, removing duplicates, and saving to validdomains..."
awk -F'//' '{print $2}' "$domain/alivesubs" | sort -u > "$domain/validdomains"

# Step 3: Process each valid domain with the given oneliner
echo "[+] Running XSS checks for each valid domain..."
while read -r validdomain; do
    # Run the XSS check and store the output in a temporary file
    temp_output=$(mktemp)
    echo "$validdomain" | gau | gf xss | uro | Gxss -p Rxss | dalfox pipe > "$temp_output"

    # Check if the output is non-empty
    if [ -s "$temp_output" ]; then
        mv "$temp_output" "$domain/${validdomain}_xss_errors.txt"
        echo "[+] XSS results saved for $validdomain in ${validdomain}_xss_errors.txt"
    else
        rm "$temp_output"
        echo "[+] No XSS errors found for $validdomain. Skipping file creation."
    fi
done < "$domain/validdomains"

echo "[+] All tasks completed for $domain."
