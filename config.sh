# -----------------------------------------------------------------------------
# Description: This is an example configuration file for the 'PADynamicSSL' script,
#              which imports certificates and private keys into a PaloAlto firewall
#              via REST and XML API calls. The script supports both PEM and PKCS12 formats
# Author: Nimrod Adam
# License: MIT License
# Version: 1.2
# Date: 07.02.2025
# -----------------------------------------------------------------------------

# Mandatory Configuration Variables
FIREWALL_IP="1.2.3.4"              # IP address of the Palo Alto firewall
API_KEY="ABC123"                  # API key for the firewall

# Local certificates configuration
CERTIFICATE_PATH=""  # Path to the certificate file, if stored locally.
PRIVATE_KEY_PATH=""  # Path to the private key file, if stored locally. Must include 'key' in name! 
PASS_PHRASE="d"       # Passphrase for the private key / keypair

CHECK_HASH="Y"       # Leave empty if there is not need to check if key/cert changed since last run
declare -A FILE_HASHES  # Associative array to store file hashes. Used to check if key changed since last run

# Decryption policy configuration 
# TO-DO, depends on how policy is defined and the corresponding API syntax

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
