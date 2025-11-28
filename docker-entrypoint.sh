#!/bin/bash
# Garfenter Tienda Entrypoint Script
# Loads RSA key from file and exports as environment variable

# If RSA key file exists and RSA_PRIVATE_KEY is not set, load it
if [ -f /app/jwt_rsa_key.pem ] && [ -z "$RSA_PRIVATE_KEY" ]; then
    export RSA_PRIVATE_KEY=$(cat /app/jwt_rsa_key.pem)
fi

# Execute the main command (supervisord)
exec "$@"
