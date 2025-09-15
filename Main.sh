#!/bin/bash

# ============================================
# Subdomain Lookup Tool (Full Version)
# Supports: assetfinder, sublist3r, amass, findomain, httprobe
# ============================================

# Color codes
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "\033[1;33m"  # Yellow text

cat <<'EOF'


                                    ,.ood888888888888boo.,
                               .od888P^""            ""^Y888bo.
                           .od8P''   ..oood88888888booo.    ``Y8bo.
                        .odP'"  .ood8888888888888888888888boo.  "`Ybo.
                      .d8'   od8'd888888888f`8888't888888888b`8bo   `Yb.
                     d8'  od8^   8888888888[  `'  ]8888888888   ^8bo  `8b
                   .8P  d88'     8888888888P      Y8888888888     `88b  Y8.
                  d8' .d8'       `Y88888888'      `88888888P'       `8b. `8b
                 .8P .88P            """"            """"            Y88. Y8.
                 88  888                                              888  88
                 88  888                                              888  88
                 88  888.        ..                        ..        .888  88
                 `8b `88b,     d8888b.od8bo.      .od8bo.d8888b     ,d88' d8'
                  Y8. `Y88.    8888888888888b    d8888888888888    .88P' .8P
                   `8b  Y88b.  `88888888888888  88888888888888'  .d88P  d8'
                     Y8.  ^Y88bod8888888888888..8888888888888bod88P^  .8P
                      `Y8.   ^Y888888888888888LS888888888888888P^   .8P'
                        `^Yb.,  `^^Y8888888888888888888888P^^'  ,.dP^'
                           `^Y8b..   ``^^^Y88888888P^^^'    ..d8P^'
                               `^Y888bo.,            ,.od888P^'
                                    "`^^Y888888888888P^^'"         




EOF


echo -e "${YELLOW}============================================="
echo -e "     Welcome to the Subdomain Lookup CLI     "
echo -e "=============================================${NC}"

# Function to check if a command exists and try installing it
check_and_install_tool() {
    tool=$1
    install_cmd=$2
    check_cmd=$3

    if ! command -v $check_cmd &>/dev/null; then
        echo -e "${YELLOW}[-] $tool is not installed. Attempting to install...${NC}"
        eval "$install_cmd"
        if ! command -v $check_cmd &>/dev/null; then
            echo -e "${RED}[!] Failed to install $tool. Please install it manually.${NC}"
            exit 1
        else
            echo -e "${GREEN}[+] $tool installed successfully.${NC}"
        fi
    else
        echo -e "${GREEN}[+] $tool is already installed.${NC}"
    fi
}

# Check and install all required tools
check_and_install_tool "assetfinder" "sudo apt  install assetfinder" "assetfinder"
check_and_install_tool "httprobe" "sudo apt  install httprobe" "httprobe"
check_and_install_tool "sublist3r" "sudo apt install sublist3r" "sublist3r"
check_and_install_tool "amass" "sudo apt install -y amass" "amass"
check_and_install_tool "findomain" "sudo apt install -y findomain" "findomain"

# Get domain from user
read -p "Enter the domain to scan (example.com): " domain
if [[ -z "$domain" ]]; then
    echo -e "${RED}[!] Domain is required.${NC}"
    exit 1
fi

# Ask output directory
echo -e "${YELLOW}Do you want to save the output in the current directory($PWD)? (y/n)${NC}"
read -p "> " save_here

if [[ "$save_here" =~ ^[Yy]$ ]]; then
    save_path="."
else
    read -p "Enter the full path to save the results: " custom_path
    if [ ! -d "$custom_path" ]; then
        echo -e "${RED}[!] Directory does not exist. Exiting.${NC}"
        exit 1
    fi
    save_path="$custom_path"
fi

# Ask for custom file name
read -p "Enter the output file name (e.g., results): " filename
if [[ "$filename" != *.txt ]]; then
    filename="${filename}.txt"
fi
output_file="$save_path/$filename"

# Create temporary directory
temp_dir=$(mktemp -d)

# Run each tool
echo -e "${YELLOW}[*] Running assetfinder...${NC}"
assetfinder -subs-only "$domain" > "$temp_dir/assetfinder.txt"

echo -e "${YELLOW}[*] Running sublist3r...${NC}"
sublist3r -d "$domain" -o "$temp_dir/sublist3r.txt" &>/dev/null

echo -e "${YELLOW}[*] Running amass (passive mode)...${NC}"
amass enum -passive -d "$domain" > "$temp_dir/amass.txt"

echo -e "${YELLOW}[*] Running findomain...${NC}"
findomain -t "$domain" -q > "$temp_dir/findomain.txt"

# Combine and deduplicate
echo -e "${YELLOW}[*] Combining and deduplicating results...${NC}"
cat "$temp_dir"/*.txt | sort -u > "$temp_dir/all_subdomains.txt"

# Probe live subdomains
echo -e "${YELLOW}[*] Probing for live subdomains...${NC}"
cat "$temp_dir/all_subdomains.txt" | httprobe | sort -u > "$output_file"

# Final output
echo -e "${GREEN}[+] Live subdomains found:${NC}"
cat "$output_file"

echo -e "${YELLOW}============================================="
echo -e "[+] Results saved to: $output_file"
echo -e "=============================================${NC}"

# Cleanup
rm -rf "$temp_dir"
