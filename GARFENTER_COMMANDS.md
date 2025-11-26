# Garfenter Tienda - Quick Command Reference

## Starting & Stopping

```bash
# Start everything (one-click deployment)
./garfenter-start.sh

# Stop all services
docker-compose -f docker-compose.garfenter.yml down

# Stop and remove all data (⚠️ WARNING: Destructive)
docker-compose -f docker-compose.garfenter.yml down -v

# Restart all services
docker-compose -f docker-compose.garfenter.yml restart

# Restart single service
docker restart garfenter-tienda
docker restart garfenter-worker
```

## Viewing Logs

```bash
# View API logs (follow mode)
docker logs -f garfenter-tienda

# View worker logs
docker logs -f garfenter-worker

# View all services
docker-compose -f docker-compose.garfenter.yml logs -f

# View specific service logs (last 100 lines)
docker logs --tail 100 garfenter-tienda
```

## Database Operations

```bash
# Create admin user
docker exec -it garfenter-tienda python manage.py createsuperuser

# Run migrations
docker exec garfenter-tienda python manage.py migrate

# Backup database
docker exec garfenter-postgres pg_dump -U garfenter garfenter_tienda > backup_$(date +%Y%m%d).sql

# Restore database
docker exec -i garfenter-postgres psql -U garfenter garfenter_tienda < backup.sql

# Connect to PostgreSQL
docker exec -it garfenter-postgres psql -U garfenter -d garfenter_tienda

# Check database size
docker exec garfenter-postgres psql -U garfenter -d garfenter_tienda -c "SELECT pg_size_pretty(pg_database_size('garfenter_tienda'));"
```

## Django Management

```bash
# Access Django shell
docker exec -it garfenter-tienda python manage.py shell

# Access container bash
docker exec -it garfenter-tienda bash

# Collect static files
docker exec garfenter-tienda python manage.py collectstatic --no-input

# Clear cache
docker exec garfenter-tienda python manage.py invalidate_cache

# Check for migrations
docker exec garfenter-tienda python manage.py showmigrations

# Create migrations
docker exec garfenter-tienda python manage.py makemigrations
```

## Celery Worker

```bash
# Check worker status
docker exec garfenter-worker celery -A saleor inspect active

# View active tasks
docker exec garfenter-worker celery -A saleor inspect active_queues

# Purge all tasks (⚠️ WARNING: Removes queued tasks)
docker exec garfenter-worker celery -A saleor purge

# Worker stats
docker exec garfenter-worker celery -A saleor inspect stats
```

## Service Health

```bash
# Check all services status
docker-compose -f docker-compose.garfenter.yml ps

# Check health of specific service
docker inspect --format='{{.State.Health.Status}}' garfenter-tienda

# View resource usage
docker stats garfenter-tienda garfenter-worker garfenter-postgres garfenter-redis
```

## Debugging

```bash
# Check environment variables
docker exec garfenter-tienda env

# Test database connection
docker exec garfenter-tienda python manage.py dbshell

# Test Redis connection
docker exec garfenter-redis redis-cli ping

# View Django settings
docker exec garfenter-tienda python manage.py diffsettings

# Run specific tests
docker exec garfenter-tienda pytest saleor/path/to/test.py
```

## Data Population (Development)

```bash
# Populate with sample data
docker exec garfenter-tienda python manage.py populatedb

# Create sample products
docker exec garfenter-tienda python manage.py populatedb --createsuperuser

# Clear all data and repopulate
docker exec garfenter-tienda python manage.py flush --no-input
docker exec garfenter-tienda python manage.py populatedb
```

## Network & Ports

```bash
# List all containers in network
docker network inspect garfenter-network

# Check open ports
docker port garfenter-tienda
docker port garfenter-dashboard
docker port garfenter-postgres
```

## Updates & Rebuilds

```bash
# Rebuild single service
docker-compose -f docker-compose.garfenter.yml build garfenter-tienda
docker-compose -f docker-compose.garfenter.yml up -d garfenter-tienda

# Rebuild all services
docker-compose -f docker-compose.garfenter.yml build
docker-compose -f docker-compose.garfenter.yml up -d

# Pull latest images
docker-compose -f docker-compose.garfenter.yml pull

# Force rebuild (no cache)
docker-compose -f docker-compose.garfenter.yml build --no-cache
```

## Volume Management

```bash
# List volumes
docker volume ls | grep garfenter

# Inspect volume
docker volume inspect garfenter-postgres-data

# Backup volume
docker run --rm -v garfenter-postgres-data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz /data

# Remove unused volumes
docker volume prune
```

## Access URLs

- GraphQL Playground: http://localhost:8000/graphql/
- Admin Dashboard: http://localhost:9000/
- Django Admin: http://localhost:8000/admin/
- Mailpit (Email UI): http://localhost:8025/
- API Health: http://localhost:8000/health/

## Environment Variables

```bash
# Edit environment
nano .env

# Reload after changes
docker-compose -f docker-compose.garfenter.yml up -d

# View current environment
docker exec garfenter-tienda env | grep -E '(DEFAULT_|SECRET_|DATABASE_|REDIS_|CELERY_)'
```

## Troubleshooting

```bash
# Check Docker daemon
docker info

# Check Docker Compose version
docker-compose --version

# Remove stopped containers
docker-compose -f docker-compose.garfenter.yml rm

# Reset everything (⚠️ DANGER: Deletes all data)
docker-compose -f docker-compose.garfenter.yml down -v
rm .env
./garfenter-start.sh

# Fix permissions
docker exec garfenter-tienda chown -R saleor:saleor /app/media

# Clear Docker cache
docker system prune -a
```

## Performance Monitoring

```bash
# CPU and Memory usage
docker stats --no-stream garfenter-tienda garfenter-worker

# Database connections
docker exec garfenter-postgres psql -U garfenter -d garfenter_tienda -c "SELECT count(*) FROM pg_stat_activity;"

# Cache keys count
docker exec garfenter-redis redis-cli DBSIZE

# Cache memory usage
docker exec garfenter-redis redis-cli INFO memory
```

## Security

```bash
# Rotate SECRET_KEY (requires restart)
# 1. Generate new key
docker exec garfenter-tienda python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
# 2. Update .env
# 3. Restart
docker-compose -f docker-compose.garfenter.yml restart

# Change database password
# 1. Update POSTGRES_PASSWORD in .env
# 2. Update DATABASE_URL in .env
# 3. Restart services
docker-compose -f docker-compose.garfenter.yml down
docker-compose -f docker-compose.garfenter.yml up -d
```

## CI/CD Integration

```bash
# Build for production
docker-compose -f docker-compose.garfenter.yml build --no-cache

# Health check (for automation)
curl -f http://localhost:8000/health/ || exit 1

# Run tests
docker exec garfenter-tienda pytest

# Check code quality
docker exec garfenter-tienda flake8 saleor
```
