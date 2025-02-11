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
    echo "ERROR: Configuration file ($CONFIG_FILE) not found"
    echo "Please make sure you have a valid configuration file in the same directory as this script!"
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# ==============================================================================
#  Function Definitions
# ==============================================================================

# Function to fetch external certificates 
fetch_cert() {
    # TO-DO: Implement the logic to fetch a certificate, probably via cert-manager
    echo "Fetching certificate from X ... (TO-DO)"
}

# Function to update decryption policy rule
update_decryption_policy() {
    # TO-DO: Implement the logic to update the decryption policy rule
    echo "Updating decryption policy rule... (TO-DO)"
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
                echo "Trying to import private key: $file_name"
                
                # Check if passphrase is provided
                if [[ -z "$PASS_PHRASE" ]]; then
                    echo "ERROR: Passphrase is required for private key import."
                    echo "Please set the passphrase in the config file: $CONFIG_FILE: "
                    exit 1
                fi

                # API call to import private key
                response=$(curl -F "file=@${file_path}" \
                    "https://${FIREWALL_IP}/api/?key=${API_KEY}&type=import&category=private-key&certificate-name=${CERTIFICATE_NAME}&format=pem&passphrase=${PASS_PHRASE}")
           
            else
                # Import certificate
                echo "Trying to import certificate: $file_name"

                # API call to import certificate
                response=$(curl -F "file=@${file_path}" \
                    "https://${FIREWALL_IP}/api/?key=${API_KEY}&type=import&category=certificate&certificate-name=${CERTIFICATE_NAME}&format=pem")
                
                echo "response: $response" 
            fi
            ;;

        # For certificates in PKCS12 format
        "p12" | "pfx")
            # Import PKCS12 keypair
            echo "Trying to import PKCS12 keypair: $file_name"
           
            # Check if passphrase is provided
            if [[ -z "$PASS_PHRASE" ]]; then
                echo "ERROR: Passphrase is required for PKCS12 import."
                echo "Please set the passphrase in the config file: $CONFIG_FILE: "
                exit 1
            fi

            # API call to import certificate
            response=$(curl -F "file=@${file_path}" \
                "https://${FIREWALL_IP}/api/?key=${API_KEY}&type=import&category=keypair&certificate-name=${CERTIFICATE_NAME}&format=pkcs12&passphrase=${PASS_PHRASE}")
            ;;
        *)
            echo "ERROR: Unsupported file type: $file_extension"
            echo "Supported extensions for import: pem | p12 | pfx"
            exit 1
            ;;
    esac

     # Check response status
    if [[ $response == *"<response status='success"* ]]; then
        echo "$file_name imported succesfully!"
    else
        echo "ERROR: importing $file_name failed: $response"
        exit 1
    fi
}

# Function to validate the candidate configuration
validate_changes() {
    echo "Validating changes..."
    
    # API call to validate changes
    response=$(curl -X POST "https://${FIREWALL_IP}/api/?type=op&cmd=<validate><full></full></validate>&key=${API_KEY}")

    # Error handling of response from API call
    if [[ $response == *"<response status='success'"* ]]; then
        echo "Changes validated successfully."
    else
        echo "ERROR: validating changes failed with the following reposnse: $response"
        exit 1
    fi
}

# Function to commit changes
commit_changes() {
    echo "Committing changes..."

    # API call to commit changes
    response=$(curl -X GET "https://${FIREWALL_IP}/api/?type=commit&cmd=<commit></commit>&key=${API_KEY}")

    # Error handling of response from API call
    if [[ $response == *"<response status='success'"* ]]; then
        echo "Changes committed successfully."
    else
        echo "ERROR: committing changes failed with the following reposnse: $response"
        exit 1
    fi
}

# ==============================================================================
#  Main Script
# ==============================================================================

# Print configuration information
printf "%-25s %-40s\n" "Configuration" "Value"
printf "%-25s %-40s\n" "--------" "-----"

# Print the configuration variables and their values in a formatted table 
while IFS='=' read -r key value; do
    key=$(echo "$key" | sed 's/#.*//' | xargs)
    value=$(echo "$value" | sed 's/#.*//' | xargs)
    if [[ -n "$key" && "$key" != \#* ]]; then
        # Replace empty values with "NONE"
        if [[ -z "$value" ]]; then
            value="NONE"
        fi
        printf "%-25s %-40s\n" "$key" "$value"
    fi
done < "$CONFIG_FILE"

# Check if required variables are set
if [[ -z "$FIREWALL_IP" || -z "$API_KEY" || -z "$CERTIFICATE_NAME" ]]; then
    echo "ERROR: One or more required variables are not set in the configuration file."
    echo "Please review your configuration at: $CONFIG_FILE"
    exit 1
fi
 
# Import certificate if set
if [[ -n "$CERTIFICATE_PATH" ]]; then 
    import_cert "$CERTIFICATE_PATH"
else 
    echo "INFO: CERTIFICATE_PATH not set. Skipping certificate import"
fi

# Import private key file if set
if [[ -n "$PRIVATE_KEY_PATH" ]]; then
    import_cert "$PRIVATE_KEY_PATH"
else 
    echo "INFO: PRIVATE_KEY_PATH not set. Skipping private key import"
fi

# Update policy if set
if [[ -n "$UPDATE_POLICY" ]]; then
    update_decryption_policy
else 
    echo "INFO: UPDATE_POLICY not set. Skipping decyrption policy update"
fi

# Validate changes if set
if [[ -n "$VALIDATE" ]]; then
    validate_changes    
else 
    echo "INFO: VALIDATE not set. Skipping committing changes"
fi

# Commit changes if set
if [[ -n "$COMMIT" ]]; then
    commit_changes    
else 
    echo "INFO: COMMIT not set. Skipping committing changes"
fi

echo "Script execution completed!"
