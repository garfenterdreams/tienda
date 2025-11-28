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

# Seed test users for authentication testing
# This ensures containers are testable immediately after creation
echo "Seeding test users..."
python /app/manage.py shell -c "
from saleor.account.models import User

# Test admin user for dashboard access
admin_email = 'admin@garfenter.com'
admin_password = 'GarfenterAdmin2024'
admin, created = User.objects.get_or_create(
    email=admin_email,
    defaults={
        'is_staff': True,
        'is_superuser': True,
        'is_active': True,
        'first_name': 'Admin',
        'last_name': 'Garfenter'
    }
)
if created:
    admin.set_password(admin_password)
    admin.save()
    print(f'Created admin user: {admin_email}')
else:
    print(f'Admin user exists: {admin_email}')

# Test customer user for storefront testing
customer_email = 'test@garfenter.com'
customer_password = 'GarfenterTest2024'
customer, created = User.objects.get_or_create(
    email=customer_email,
    defaults={
        'is_staff': False,
        'is_superuser': False,
        'is_active': True,
        'first_name': 'Test',
        'last_name': 'Customer'
    }
)
if created:
    customer.set_password(customer_password)
    customer.save()
    print(f'Created customer user: {customer_email}')
else:
    print(f'Customer user exists: {customer_email}')
" 2>/dev/null || echo "Test users seeding skipped"

# Execute the main command (supervisord)
exec "$@"
