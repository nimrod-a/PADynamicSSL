# -----------------------------------------------------------------------------
# Description: This is an example configuration file for the 'PADynamicSSL' script,
#              which imports certificates and private keys into a PaloAlto firewall
#              via REST and XML API calls. The script supports both PEM and PKCS12 formats
# Author: Nimrod Adam
# License: MIT License
# Version: 1.7
# Date: 12.02.2025
# -----------------------------------------------------------------------------

# Mandatory Configuration Variables
FIREWALL_IP="1.2.3.4"              # IP address of the Palo Alto firewall
API_KEY="ABC123"                  # API key for the firewall

# Local certificates configuration
CERTIFICATE_PATH=""	    # Use for .p12, pfx, .cer, .crt and .pem files 
PRIVATE_KEY_PATH="" 	# Use only for .key files. 
PASS_PHRASE=""	        # Passphrase for the private key / keypair. If no passphrase is set, enter empty single quotes
PEM_INCLUDES_KEY="Y"	# Set if the private key is included in the PEM certificate
CHECK_HASH="Y"          # Leave empty if there is not need to check if key/cert changed since last run
declare -A FILE_HASHES  # Associative array to store file hashes. Used to check if cert changed since last run

# Decryption policy configuration 
POLICY_NAME=""  # Name of the decryption policy must be unique
CATEGORY="any"
DESTINATION="any"
DESTINATION_HIP="any"
FROM_ZONE="Untrust"
NEGATE_SOURCE="no"
DECRYPTION_PROFILE="default"
SERVICE="any"
SOURCE="any"
SOURCE_USER="any"
SOURCE_HIP="any"
TO_ZONE="Trust"
CERTIFICATE_NAME_FW="" # Name of the certificate on the firewall  

# Other configuration (unset e.g for testing purposes)
VALIDATE=""        # Leave empty if changes should not be validated
COMMIT=""          # Leave empty if changes should not be commited
UPDATE_POLICY=""   # Leave empty if policy should not be updated
TEST_CONNECTIVITY="" # Leave empty to skip connectivity checks. Only for testing!

# -----------------------------------------------------------------------------
# Additional Notes: 
# In case you don't have an API Key, you can request it using the following command: 
# curl --location https://firewall_ip/api/?type=keygen --request POST 
# --data user=username&password=your_password
# The response will include the key. 
# You will need to enable API access first on the firewall first:
# https://docs.paloaltonetworks.com/pan-os/11-1/pan-os-panorama-api/pan-os-api-authentication/enable-api-access
# 
# -----------------------------------------------------------------------------
