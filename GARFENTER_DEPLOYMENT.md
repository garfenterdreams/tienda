# Garfenter Tienda - One-Click Deployment Guide

This deployment setup provides a production-ready Saleor e-commerce platform configured specifically for Guatemala.

## Quick Start

### Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- 4GB RAM minimum
- 10GB free disk space

### One-Click Deployment

Simply run:

```bash
./garfenter-start.sh
```

That's it! The script will:
1. Check dependencies
2. Create environment configuration
3. Generate secure SECRET_KEY
4. Build and start all services
5. Run database migrations
6. Display access URLs

## Services Included

The deployment includes the following services:

| Service | Container Name | Port | Description |
|---------|---------------|------|-------------|
| API Server | garfenter-tienda | 8000 | Saleor GraphQL API |
| Dashboard | garfenter-dashboard | 9000 | Admin Dashboard UI |
| PostgreSQL | garfenter-postgres | 5432 | Database |
| Redis | garfenter-redis | 6379 | Cache & Message Broker |
| Celery Worker | garfenter-worker | - | Background Tasks |
| Mailpit | garfenter-mailpit | 8025, 1025 | Email Testing |

## Access Points

After deployment, access these URLs:

- **GraphQL API**: http://localhost:8000/graphql/
- **Admin Dashboard**: http://localhost:9000/
- **Django Admin**: http://localhost:8000/admin/
- **Email UI (Mailpit)**: http://localhost:8025/

## Guatemala Configuration

The deployment is pre-configured for Guatemala:

- **Currency**: GTQ (Quetzal Guatemalteco)
- **Country**: GT (Guatemala)
- **Language**: es (Spanish)
- **Timezone**: America/Guatemala

## Initial Setup

### 1. Create Admin User

After deployment, create a superuser:

```bash
docker exec -it garfenter-tienda python manage.py createsuperuser
```

Follow the prompts to set:
- Email address
- Password

### 2. Access Dashboard

1. Go to http://localhost:9000/
2. Login with your superuser credentials
3. Complete the initial setup wizard

### 3. Configure Your Store

In the dashboard:
- Set up your store details
- Configure shipping methods
- Add product categories
- Configure payment gateways
- Customize email templates

## Environment Configuration

### Default Configuration

The `.env` file is auto-generated with:

```bash
DEFAULT_CURRENCY=GTQ
DEFAULT_COUNTRY=GT
DEFAULT_LANGUAGE=es
TIME_ZONE=America/Guatemala
```

### Custom Configuration

To customize, edit `.env` before starting:

```bash
cp .env.garfenter.example .env
# Edit .env with your settings
./garfenter-start.sh
```

### Important Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| SECRET_KEY | auto-generated | Django secret key |
| POSTGRES_PASSWORD | garfenter2024 | Database password |
| DEBUG | False | Debug mode (use False in production) |
| ALLOWED_HOSTS | localhost,127.0.0.1 | Allowed hostnames |
| DEFAULT_FROM_EMAIL | noreply@garfenter.com | Email sender address |

## Management Commands

### Service Control

```bash
# View logs
docker logs -f garfenter-tienda

# Stop all services
docker-compose -f docker-compose.garfenter.yml down

# Stop and remove volumes (WARNING: deletes data)
docker-compose -f docker-compose.garfenter.yml down -v

# Restart services
docker-compose -f docker-compose.garfenter.yml restart

# Rebuild services
docker-compose -f docker-compose.garfenter.yml up -d --build
```

### Database Operations

```bash
# Run migrations
docker exec garfenter-tienda python manage.py migrate

# Create database backup
docker exec garfenter-postgres pg_dump -U garfenter garfenter_tienda > backup.sql

# Restore database backup
docker exec -i garfenter-postgres psql -U garfenter garfenter_tienda < backup.sql

# Access PostgreSQL shell
docker exec -it garfenter-postgres psql -U garfenter -d garfenter_tienda
```

### Application Commands

```bash
# Shell access
docker exec -it garfenter-tienda bash

# Django shell
docker exec -it garfenter-tienda python manage.py shell

# Create superuser
docker exec -it garfenter-tienda python manage.py createsuperuser

# Collect static files
docker exec garfenter-tienda python manage.py collectstatic --no-input

# Clear cache
docker exec garfenter-tienda python manage.py invalidate_cache

# Populate sample data (development only)
docker exec garfenter-tienda python manage.py populatedb
```

### Celery Worker

```bash
# View worker logs
docker logs -f garfenter-worker

# Restart worker
docker restart garfenter-worker

# Check worker status
docker exec garfenter-worker celery -A saleor inspect active
```

## Production Deployment

### Security Checklist

- [ ] Change `POSTGRES_PASSWORD` in `.env`
- [ ] Verify `SECRET_KEY` is unique and secure
- [ ] Set `DEBUG=False`
- [ ] Configure `ALLOWED_HOSTS` for your domain
- [ ] Set up SSL/TLS certificates
- [ ] Configure real SMTP email service
- [ ] Set up regular database backups
- [ ] Configure proper firewall rules
- [ ] Enable rate limiting
- [ ] Set up monitoring and logging

### SSL/HTTPS Configuration

For production with HTTPS:

```bash
# In .env
ENABLE_SSL=True
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
```

### Email Configuration

Replace Mailpit with real SMTP:

```bash
# In .env
EMAIL_URL=smtp://username:password@smtp.gmail.com:587/?tls=True
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
```

### Cloud Storage (Optional)

For production media storage:

```bash
# In .env
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_STORAGE_BUCKET_NAME=garfenter-media
AWS_S3_REGION_NAME=us-east-1
```

## Troubleshooting

### Services won't start

```bash
# Check Docker status
docker ps -a

# Check logs
docker logs garfenter-tienda
docker logs garfenter-postgres
docker logs garfenter-redis

# Restart all services
docker-compose -f docker-compose.garfenter.yml restart
```

### Database connection errors

```bash
# Check PostgreSQL is running
docker exec garfenter-postgres pg_isready -U garfenter

# Verify database exists
docker exec garfenter-postgres psql -U garfenter -l
```

### Port conflicts

If ports 8000, 9000, 5432, or 6379 are already in use:

1. Stop conflicting services
2. Or modify ports in `docker-compose.garfenter.yml`

### Reset everything

```bash
# WARNING: This deletes all data
docker-compose -f docker-compose.garfenter.yml down -v
rm .env
./garfenter-start.sh
```

## Performance Tuning

### For development

```bash
# In docker-compose.garfenter.yml
# Reduce workers:
command: uvicorn saleor.asgi:application --host=0.0.0.0 --port=8000 --workers=1
```

### For production

- Increase worker count based on CPU cores
- Add horizontal scaling with load balancer
- Configure CDN for static files
- Use managed PostgreSQL service
- Use Redis Cluster for high availability

## Health Checks

All services include health checks:

```bash
# Check service health
docker-compose -f docker-compose.garfenter.yml ps
```

Services should show "healthy" status.

## Backup Strategy

### Automated backups

Create a backup script:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec garfenter-postgres pg_dump -U garfenter garfenter_tienda | gzip > "backup_$DATE.sql.gz"
```

Schedule with cron:
```bash
# Run daily at 2 AM
0 2 * * * /path/to/backup-script.sh
```

## Support

For issues specific to Garfenter deployment:
- Check logs: `docker logs garfenter-tienda`
- Review environment: `docker exec garfenter-tienda env`

For Saleor-specific questions:
- Documentation: https://docs.saleor.io/
- Community: https://github.com/saleor/saleor/discussions

## Architecture

```
┌─────────────────┐
│   Dashboard     │ (Port 9000)
│  (React SPA)    │
└────────┬────────┘
         │
         │ GraphQL
         ▼
┌─────────────────┐     ┌──────────────┐
│   Saleor API    │────▶│  PostgreSQL  │
│   (Django)      │     │  (Database)  │
└────────┬────────┘     └──────────────┘
         │
         │ Celery
         ▼
┌─────────────────┐     ┌──────────────┐
│  Celery Worker  │────▶│    Redis     │
│  (Background)   │     │   (Cache)    │
└─────────────────┘     └──────────────┘
         │
         │ SMTP
         ▼
┌─────────────────┐
│    Mailpit      │ (Port 8025)
│  (Email Test)   │
└─────────────────┘
```

## License

This deployment configuration is provided as-is for Garfenter Tienda.
Saleor is licensed under BSD-3-Clause.
