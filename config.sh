# -----------------------------------------------------------------------------
# Description: This is an example configuration file for the 'PADynamicSSL' script,
#              which imports certificates and private keys into a PaloAlto firewall
#              via REST and XML API calls. The script supports both PEM and PKCS12 formats, 
#              with local and external certificate setups.   
# Author: Nimrod Adam
# License: MIT License
# Version: 1.2
# Date: 07.02.2025
# -----------------------------------------------------------------------------

# Mandatory Configuration Variables
FIREWALL_IP="1.2.3.4"              # IP address of the Palo Alto firewall
API_KEY="ABC123"                  # API key for the firewall
CERTIFICATE_NAME="SSCert"   # Name of the certificate once imported in the firewall.  Default: SSCert

# Local certificates configuration
CERTIFICATE_PATH=""  # Path to the certificate file, if stored locally
PRIVATE_KEY_PATH=""  # Path to the private key file, if stored locally. Must include 'key' in name! 
PASS_PHRASE=""       # Passphrase for the private key

# Remote certificate configuration 
# TO-DO, depends on how cert is fetched

# Decryption policy configuration 
# TO-DO, depends on how policy is defined and the corresponding API syntax

# Other configuration (unset e.g for testing purposes)
VALIDATE="y"        # Leave empty if changes should not be validated
COMMIT="Y"          # Leave empty if changes should not be commited
UPDATE_POLICY="Y"   # Leave empty if policy should not be updated
