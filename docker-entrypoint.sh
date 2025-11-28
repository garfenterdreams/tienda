#!/bin/bash
# Garfenter Tienda Entrypoint Script
# - Loads RSA key for JWT tokens
# - Runs database migrations automatically
# - Ensures containers are replicable and can be created dynamically

set -e

# If RSA key file exists and RSA_PRIVATE_KEY is not set, load it
if [ -f /app/jwt_rsa_key.pem ] && [ -z "$RSA_PRIVATE_KEY" ]; then
    export RSA_PRIVATE_KEY=$(cat /app/jwt_rsa_key.pem)
fi

# Run database migrations automatically on startup
# This ensures the container is self-sufficient and can be created dynamically
echo "Running database migrations..."
python /app/manage.py migrate --noinput || {
    echo "Warning: Migrations failed, but continuing startup..."
}

# Create default site settings if they don't exist
echo "Ensuring site settings exist..."
python /app/manage.py shell -c "
from django.contrib.sites.models import Site
from saleor.site.models import SiteSettings
site, _ = Site.objects.get_or_create(id=1, defaults={'domain': 'tienda.garfenter.com', 'name': 'Garfenter Tienda'})
SiteSettings.objects.get_or_create(site=site)
print('Site settings configured')
" 2>/dev/null || echo "Site settings already exist or skipped"

# Execute the main command (supervisord)
exec "$@"
