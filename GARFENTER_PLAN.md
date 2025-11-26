# GARFENTER PLAN: Garfenter Tienda (saleor)

> **⭐ PREFERRED PRODUCT** - Selected as best E-Commerce platform for Garfenter Suite (Score: 9/10)

**Product Name:** Garfenter Tienda
**Based On:** Saleor (21.8K+ GitHub Stars)
**Category:** Headless E-Commerce Platform
**Original Language:** English (with Spanish support)

---

## Executive Summary

Saleor is an enterprise-grade, API-first e-commerce platform with excellent existing Spanish support and Docker configuration. This plan focuses on Guatemala-specific customization and Garfenter branding.

---

## 1. LOCALIZATION PLAN

### Current Status: SPANISH SUPPORTED ✓
- 27 Spanish regional variants configured
- Includes `es-GT` (Guatemala) variant
- Full i18n infrastructure with Django/Babel
- Translation files in `/locale` directory

### Enhancement Plan

#### Phase 1: Guatemala-Specific Translations (Week 1)
```
Tasks:
├── Create es_GT.po file with Guatemala terminology
├── Configure Guatemala as default locale
├── Add GTQ (Quetzal) currency configuration
├── Configure Guatemala address validation rules
└── Add department/municipality address fields
```

**Create:** `locale/es_GT/LC_MESSAGES/django.po`
```po
# Guatemala Spanish Translations for Garfenter Comercio

msgid "Checkout"
msgstr "Finalizar Compra"

msgid "Add to Cart"
msgstr "Agregar al Carrito"

msgid "Province"
msgstr "Departamento"

msgid "City"
msgstr "Municipio"

msgid "Postal Code"
msgstr "Código Postal"

msgid "Tax"
msgstr "IVA"
```

#### Phase 2: Currency & Tax Configuration (Week 1)
```python
# settings.py additions
DEFAULT_CURRENCY = "GTQ"
DEFAULT_COUNTRY = "GT"

GUATEMALA_TAX_CONFIG = {
    "IVA": {
        "rate": Decimal("0.12"),
        "name": "IVA",
        "description": "Impuesto al Valor Agregado"
    }
}

# Address configuration for Guatemala
GOOGLE_I18N_RULES_OVERRIDE = {
    "GT": {
        "fmt": "%N%n%O%n%A%n%C, %S%n%Z",
        "require": "ACS",
        "state_name_type": "department",
        "locality_name_type": "municipality"
    }
}
```

#### Phase 3: Guatemala Departments Data
```python
# Add to address validation
GUATEMALA_DEPARTMENTS = [
    ("GT-GU", "Guatemala"),
    ("GT-AV", "Alta Verapaz"),
    ("GT-BV", "Baja Verapaz"),
    ("GT-CM", "Chimaltenango"),
    ("GT-CQ", "Chiquimula"),
    ("GT-PR", "El Progreso"),
    ("GT-ES", "Escuintla"),
    ("GT-HU", "Huehuetenango"),
    ("GT-IZ", "Izabal"),
    ("GT-JA", "Jalapa"),
    ("GT-JU", "Jutiapa"),
    ("GT-PE", "Petén"),
    ("GT-QZ", "Quetzaltenango"),
    ("GT-QC", "Quiché"),
    ("GT-RE", "Retalhuleu"),
    ("GT-SA", "Sacatepéquez"),
    ("GT-SM", "San Marcos"),
    ("GT-SR", "Santa Rosa"),
    ("GT-SO", "Sololá"),
    ("GT-SU", "Suchitepéquez"),
    ("GT-TO", "Totonicapán"),
    ("GT-ZA", "Zacapa"),
]
```

---

## 2. CONTAINERIZATION PLAN

### Current Status: DOCKER READY ✓
- Production Dockerfile exists
- Dev container with docker-compose
- PostgreSQL, Redis, email services configured

### Enhancement Plan

#### Phase 1: Garfenter Docker Configuration

**Create:** `docker-compose.garfenter.yml`
```yaml
version: '3.8'

services:
  garfenter-comercio:
    build:
      context: .
      dockerfile: Dockerfile
    image: garfenter/comercio:latest
    container_name: garfenter-comercio
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgres://garfenter:${DB_PASSWORD}@garfenter-postgres:5432/garfenter_comercio
      - REDIS_URL=redis://garfenter-redis:6379/0
      - SECRET_KEY=${SECRET_KEY}
      - ALLOWED_HOSTS=localhost,garfenter.com,*.garfenter.com
      - DEFAULT_CURRENCY=GTQ
      - DEFAULT_COUNTRY=GT
      - DEFAULT_LANGUAGE=es-GT
      - DEFAULT_LOCALE=es_GT
      - GARFENTER_BRAND=true
      - TIME_ZONE=America/Guatemala
    depends_on:
      - garfenter-postgres
      - garfenter-redis
    networks:
      - garfenter-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health/"]
      interval: 30s
      timeout: 10s
      retries: 3

  garfenter-dashboard:
    image: ghcr.io/saleor/saleor-dashboard:3.20.5
    container_name: garfenter-dashboard
    ports:
      - "9000:80"
    environment:
      - API_URL=http://garfenter-comercio:8000/graphql/
    networks:
      - garfenter-network
    restart: unless-stopped

  garfenter-postgres:
    image: postgres:15-alpine
    container_name: garfenter-postgres
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=garfenter
      - POSTGRES_PASSWORD=${DB_PASSWORD:-garfenter123}
      - POSTGRES_DB=garfenter_comercio
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - garfenter-network
    restart: unless-stopped

  garfenter-redis:
    image: redis:7-alpine
    container_name: garfenter-redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - garfenter-network
    restart: unless-stopped

  garfenter-worker:
    build:
      context: .
      dockerfile: Dockerfile
    image: garfenter/comercio:latest
    container_name: garfenter-worker
    command: celery -A saleor worker --loglevel=info
    environment:
      - DATABASE_URL=postgres://garfenter:${DB_PASSWORD}@garfenter-postgres:5432/garfenter_comercio
      - REDIS_URL=redis://garfenter-redis:6379/0
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      - garfenter-postgres
      - garfenter-redis
    networks:
      - garfenter-network
    restart: unless-stopped

  garfenter-mailpit:
    image: axllent/mailpit
    container_name: garfenter-mailpit
    ports:
      - "8025:8025"
      - "1025:1025"
    networks:
      - garfenter-network

networks:
  garfenter-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
```

#### Phase 2: One-Click Start Script

**Create:** `garfenter-start.sh`
```bash
#!/bin/bash
set -e

echo "╔══════════════════════════════════════════╗"
echo "║   GARFENTER COMERCIO - Headless Commerce ║"
echo "║   Iniciando servicios...                 ║"
echo "╚══════════════════════════════════════════╝"

# Generate secret key if not set
if [ -z "$SECRET_KEY" ]; then
    export SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
fi

# Create .env if needed
if [ ! -f .env ]; then
    cat > .env << EOF
SECRET_KEY=$SECRET_KEY
DB_PASSWORD=garfenter123
DEBUG=False
EOF
    echo "✓ Archivo .env creado"
fi

# Start services
docker-compose -f docker-compose.garfenter.yml up -d --build

# Wait for database
echo "Esperando base de datos..."
sleep 10

# Run migrations
docker-compose -f docker-compose.garfenter.yml exec -T garfenter-comercio python manage.py migrate

# Create superuser if needed
docker-compose -f docker-compose.garfenter.yml exec -T garfenter-comercio python manage.py createsuperuser --noinput --email admin@garfenter.com || true

echo ""
echo "✓ Garfenter Comercio iniciado correctamente!"
echo ""
echo "Accesos:"
echo "  - GraphQL API:     http://localhost:8000/graphql/"
echo "  - Dashboard:       http://localhost:9000"
echo "  - Email Testing:   http://localhost:8025"
echo ""
```

---

## 3. PERSONALIZATION/BRANDING PLAN

### Current Status
- Saleor branding throughout
- Configurable via SiteSettings model

### Implementation Plan

#### Phase 1: Logo & Visual Assets

**Replace:**
```
saleor/static/images/
├── logo-light.svg → garfenter-logo-light.svg
├── logo-dark.svg → garfenter-logo-dark.svg
└── saleor-logo-sign.png → garfenter-icon.png
```

**Create Garfenter theme colors:**
```css
/* garfenter-theme.css */
:root {
  --garfenter-primary: #1E3A8A;
  --garfenter-accent: #F59E0B;
  --garfenter-success: #059669;
  --garfenter-text: #374151;
}
```

#### Phase 2: Site Configuration

**Create migration for default Garfenter site:**
```python
# migrations/0001_garfenter_site.py
def create_garfenter_site(apps, schema_editor):
    Site = apps.get_model('sites', 'Site')
    SiteSettings = apps.get_model('site', 'SiteSettings')

    site, _ = Site.objects.update_or_create(
        id=1,
        defaults={
            'domain': 'garfenter.com',
            'name': 'Garfenter Comercio'
        }
    )

    SiteSettings.objects.update_or_create(
        site=site,
        defaults={
            'header_text': 'Garfenter Comercio',
            'description': 'Plataforma de comercio electrónico para Latinoamérica',
            'default_mail_sender_name': 'Garfenter',
            'default_mail_sender_address': 'noreply@garfenter.com',
        }
    )
```

#### Phase 3: Email Templates

**Customize email templates:**
```
templates/templated_email/
├── garfenter_base.html (branded header/footer)
├── order/
│   ├── confirm_order_es.html
│   ├── shipping_es.html
│   └── payment_es.html
└── account/
    ├── welcome_es.html
    └── password_reset_es.html
```

---

## 4. GUATEMALA-SPECIFIC FEATURES

### Tax Plugin
```python
# plugins/garfenter_guatemala_tax/plugin.py
class GuatemalaTaxPlugin(BasePlugin):
    PLUGIN_ID = "garfenter.taxes.guatemala"
    PLUGIN_NAME = "Guatemala IVA"
    DEFAULT_CONFIGURATION = [
        {"name": "iva_rate", "value": "0.12"},
    ]

    def calculate_checkout_line_total(self, checkout_info, lines, ...):
        # Apply 12% IVA
        subtotal = line.total_price.net
        iva = subtotal * Decimal("0.12")
        return TaxedMoney(net=subtotal, gross=subtotal + iva)
```

### Payment Integrations (Future)
- Visanet Guatemala
- BAC Credomatic
- Banco Industrial
- Tigo Money

---

## 5. IMPLEMENTATION TIMELINE

| Phase | Task | Duration | Priority |
|-------|------|----------|----------|
| 1 | Docker Garfenter config | 1 day | HIGH |
| 2 | Guatemala locale setup | 2 days | HIGH |
| 3 | Logo/branding assets | 1 day | MEDIUM |
| 4 | Guatemala tax plugin | 3 days | HIGH |
| 5 | Email templates ES | 2 days | MEDIUM |
| 6 | Testing & QA | 3 days | HIGH |

**Total Estimated Time:** 2 weeks

---

## 6. FILES TO CREATE/MODIFY

### New Files
- [ ] `docker-compose.garfenter.yml`
- [ ] `garfenter-start.sh`
- [ ] `.env.example`
- [ ] `locale/es_GT/LC_MESSAGES/django.po`
- [ ] `saleor/plugins/garfenter_guatemala_tax/`
- [ ] Logo assets in `static/images/`
- [ ] Email templates in Spanish

### Files to Modify
- [ ] `saleor/settings.py` - Default locale/currency
- [ ] `saleor/core/languages.py` - Prioritize es_GT
- [ ] `saleor/site/models.py` - Default branding

---

## 7. SUCCESS METRICS

- [ ] Single command deployment working
- [ ] Guatemala Spanish as default
- [ ] GTQ currency configured
- [ ] 12% IVA calculation working
- [ ] Garfenter branding on dashboard
- [ ] Email templates in Spanish
- [ ] Health checks passing

---

*Plan Version: 1.0*
*Created for: Garfenter Product Suite*
*Target Market: Guatemala & Central America*
