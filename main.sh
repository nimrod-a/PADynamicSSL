#!/bin/bash

# -----------------------------------------------------------------------------
# Description: The script imports certificates and private keys into a PaloAlto firewall
#              via REST and XML API calls.It supports both PEM and PKCS12 formats, 
#              with local and external certificate setups. .
# Author: Nimrod Adam
# Email: na@caskan.com
# License: MIT License
# Version: 1.2
# Date: 07.02.2025
# -----------------------------------------------------------------------------

# Exit script on any errors
set -e

# Configuration file path
CONFIG_FILE="config.sh" 

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    printf "ERROR: Configuration file ($CONFIG_FILE) not found\n"
    printf "Please make sure you have a valid configuration file in the same directory as this script!\n"
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# Check if required variables are set
if [[ -z "$FIREWALL_IP" || -z "$API_KEY" || -z "$CERTIFICATE_NAME" ]]; then
    printf "ERROR: One or more required variables are not set in the configuration file.\n"
    printf "Please review your configuration at: $CONFIG_FILE\n"
    exit 1
fi
 

# ==============================================================================
#  Function Definitions
# ==============================================================================

# Function to test firewall connection
test_connect() {
    # Test firewall connectivity
    printf "Testing connection to the firewall...\n\n"

    if ping -c 1 $FIREWALL_IP &> /dev/null; then
        printf "Firewall is up!\n"
    else
        printf "ERROR: Failed connecting to the firewall\n"
        printf "Please ensure that the firewall is up and allows traffic from this host\n"
        exit 1
    fi

    # Test API key access by requesting firewall information
    printf "Testing API access\n"

     response=$(curl -X POST "https://${FIREWALL_IP}/api/?type=op&cmd=<show><system><info></info></system></show>&key=${API_KEY}")

    # Error handling of response from API call
    if [[ $response == *"<response status='success'"* ]]; then
        printf "API access successful.\n"
    else
        printf "ERROR: API access failed with the following error: $response\n"
        printf "Please ensure you have set a valid API key in the configuration file [config.sh]\n"
        exit 1
    fi
}

# Function to fetch external certificates 
fetch_cert() {
    # TO-DO: Implement the logic to fetch a certificate, probably via cert-manager
    printf "Fetching certificate from X ... (TO-DO)\n"
}

# Function to update decryption policy rule
update_decryption_policy() {
    # TO-DO: Implement the logic to update the decryption policy rule
    printf "Updating decryption policy rule... (TO-DO)\n"
}

# Function to send an import API call to the firewall, automatically determines certificate format 
import_cert() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    local file_extension="${file_name##*.}"

    case "$file_extension" in
        # For certificates in PEM format
        "pem")
            if [[ "$file_name" == *"key"* ]]; then
                # Import private key (if not using keypair)
                printf "Trying to import private key: $file_name\n"
                
                # Check if passphrase is provided
                if [[ -z "$PASS_PHRASE" ]]; then
                    printf "ERROR: Passphrase is required for private key import.\n"
                    printf "Please set the passphrase in the config file [config.sh] \n"
                    exit 1
                fi
                
                # API call to import private key
                response=$(curl -F "file=@${file_path}" \
                    "https://${FIREWALL_IP}/api/?key=${API_KEY}&type=import&category=private-key&certificate-name=${CERTIFICATE_NAME}&format=pem&passphrase=${PASS_PHRASE}")
           
            else
                # Import certificate
                printf "Trying to import certificate: $file_name\n"

                # API call to import certificate
                response=$(curl -F "file=@${file_path}" \
                    "https://${FIREWALL_IP}/api/?key=${API_KEY}&type=import&category=certificate&certificate-name=${CERTIFICATE_NAME}&format=pem")
                
            fi
            ;;

        # For certificates in PKCS12 format
        "p12" | "pfx")
            # Import PKCS12 keypair
            printf "Trying to import PKCS12 keypair: $file_name\n"
           
            # Check if passphrase is provided
            if [[ -z "$PASS_PHRASE" ]]; then
                printf "ERROR: Passphrase is required for PKCS12 import.\n"
                printf "Please set the passphrase in the config file [config.sh]\n"
                exit 1
            fi

            # API call to import certificate
            response=$(curl -F "file=@${file_path}" \
                "https://${FIREWALL_IP}/api/?key=${API_KEY}&type=import&category=keypair&certificate-name=${CERTIFICATE_NAME}&format=pkcs12&passphrase=${PASS_PHRASE}")
            ;;
        *)
            printf "ERROR: Unsupported file type: $file_extension\n"
            printf "Supported extensions for import: pem | p12 | pfx\n"
            exit 1
            ;;
    esac

     # Check response status
    if [[ $response == *"<response status='success"* ]]; then
        printf "$file_name imported succesfully!\n"
    else
        printf "ERROR: importing $file_name failed: $response\n"
        exit 1
    fi
}

# Function to validate the candidate configuration
validate_changes() {
    printf "Validating changes...\n"
    
    # API call to validate changes
    response=$(curl -X POST "https://${FIREWALL_IP}/api/?type=op&cmd=<validate><full></full></validate>&key=${API_KEY}")

    # Error handling of response from API call
    if [[ $response == *"<response status='success'"* ]]; then
        printf "Changes validated successfully!\n"
    else
        printf "ERROR: validating changes failed with the following reponse: $response\n"
        exit 1
    fi
}

# Function to commit changes
commit_changes() {
    printf "Committing changes...\n"

    # API call to commit changes
    response=$(curl -X GET "https://${FIREWALL_IP}/api/?type=commit&cmd=<commit></commit>&key=${API_KEY}")

    # Error handling of response from API call
    if [[ $response == *"<response status='success'"* ]]; then
        printf "Changes committed successfully.\n"
    else
        printf "ERROR: committing changes failed with the following reposnse: $response\n"
        exit 1
    fi
}

# Print configuration information
print_configuration() {
printf "Checking configuration...\n\n"
printf "%-25s %-40s\n" "Configuration" "Value"
printf "%-25s %-40s\n" "--------" "-----"

# Print the configuration variables and their values in a formatted table 
while IFS='=' read -r key value; do
    key=$(printf "$key" | sed 's/#.*//' | xargs)
    value=$(printf "$value" | sed 's/#.*//' | xargs)
    if [[ -n "$key" && "$key" != \#* ]]; then
        # Replace empty values with "NONE"
        if [[ -z "$value" ]]; then
            value="NONE"
        fi
        printf "%-25s %-40s\n" "$key" "$value"
    fi
done < "$CONFIG_FILE"
# print empty line at the end
echo
}

# ==============================================================================
#  Main Script
# ==============================================================================

# Print current configuration 
print_configuration

# Test connection to the firewall & API Key 
test_connect

# Import certificate if set
if [[ -n "$CERTIFICATE_PATH" ]]; then 
    import_cert "$CERTIFICATE_PATH"
else 
    printf "INFO: CERTIFICATE_PATH not set. Skipping certificate import\n"
fi

# Import private key file if set
if [[ -n "$PRIVATE_KEY_PATH" ]]; then
    import_cert "$PRIVATE_KEY_PATH"
else 
    printf "INFO: PRIVATE_KEY_PATH not set. Skipping private key import\n"
fi

# Update policy if set
if [[ -n "$UPDATE_POLICY" ]]; then
    update_decryption_policy
else 
    printf "INFO: UPDATE_POLICY not set. Skipping decyrption policy update\n"
fi

# Validate changes if set
if [[ -n "$VALIDATE" ]]; then
    validate_changes    
else 
    printf "INFO: VALIDATE not set. Skipping committing changes\n"
fi

# Commit changes if set
if [[ -n "$COMMIT" ]]; then
    commit_changes    
else 
    printf "INFO: COMMIT not set. Skipping committing changes\n"
fi

printf "Script execution completed!"
