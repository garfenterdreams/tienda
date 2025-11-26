#!/bin/bash

# =============================================================================
# GARFENTER TIENDA - One-Click Deployment Script
# =============================================================================
# This script sets up and starts Garfenter Tienda (Saleor) with all services
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# =============================================================================
# Functions
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                       ║"
    echo "║   ██████╗  █████╗ ██████╗ ███████╗███████╗███╗   ██╗████████╗███████╗║"
    echo "║  ██╔════╝ ██╔══██╗██╔══██╗██╔════╝██╔════╝████╗  ██║╚══██╔══╝██╔════╝║"
    echo "║  ██║  ███╗███████║██████╔╝█████╗  █████╗  ██╔██╗ ██║   ██║   █████╗  ║"
    echo "║  ██║   ██║██╔══██║██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ║"
    echo "║  ╚██████╔╝██║  ██║██║  ██║██║     ███████╗██║ ╚████║   ██║   ███████╗║"
    echo "║   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝║"
    echo "║                                                                       ║"
    echo "║                         TIENDA GUATEMALTECA                           ║"
    echo "║                    Powered by Saleor E-commerce                       ║"
    echo "║                                                                       ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

generate_secret_key() {
    # Generate a safe secret key without special characters that could break sed
    openssl rand -hex 32 2>/dev/null || \
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64
}

check_dependencies() {
    print_info "Checking dependencies..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    print_step "All dependencies are installed"
}

create_env_file() {
    if [ ! -f .env ]; then
        print_info "Creating .env file from template..."

        if [ -f .env.garfenter.example ]; then
            cp .env.garfenter.example .env
        else
            print_warning ".env.garfenter.example not found, creating minimal .env file..."
            cat > .env << EOF
SECRET_KEY=changeme
DEBUG=False
POSTGRES_PASSWORD=garfenter2024
DEFAULT_CURRENCY=GTQ
DEFAULT_COUNTRY=GT
DEFAULT_LANGUAGE=es
TIME_ZONE=America/Guatemala
DEFAULT_FROM_EMAIL=noreply@garfenter.com
ALLOWED_HOSTS=localhost,127.0.0.1,garfenter-tienda
CACHE_URL=redis://garfenter-redis:6379/0
CELERY_BROKER_URL=redis://garfenter-redis:6379/1
DASHBOARD_URL=http://localhost:9000/
EMAIL_URL=smtp://mailpit:1025
HTTP_IP_FILTER_ALLOW_LOOPBACK_IPS=True
EOF
        fi

        # Generate and set SECRET_KEY
        print_info "Generating SECRET_KEY..."
        SECRET_KEY=$(generate_secret_key)

        # Replace SECRET_KEY in .env file
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|SECRET_KEY=changeme.*|SECRET_KEY=$SECRET_KEY|g" .env
        else
            # Linux
            sed -i "s|SECRET_KEY=changeme.*|SECRET_KEY=$SECRET_KEY|g" .env
        fi

        print_step ".env file created with generated SECRET_KEY"
    else
        print_info ".env file already exists, skipping creation"

        # Check if SECRET_KEY needs to be generated
        if grep -q "SECRET_KEY=changeme" .env; then
            print_warning "Detected default SECRET_KEY, generating new one..."
            SECRET_KEY=$(generate_secret_key)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|SECRET_KEY=changeme.*|SECRET_KEY=$SECRET_KEY|g" .env
            else
                sed -i "s|SECRET_KEY=changeme.*|SECRET_KEY=$SECRET_KEY|g" .env
            fi
            print_step "New SECRET_KEY generated"
        fi
    fi
}

start_services() {
    print_info "Building and starting Docker services..."
    echo ""

    # Use docker compose (v2) if available, otherwise docker-compose (v1)
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi

    $COMPOSE_CMD -f docker-compose.garfenter.yml up -d --build

    print_step "Docker services started"
}

wait_for_db() {
    print_info "Waiting for PostgreSQL to be ready..."

    max_attempts=30
    attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker exec garfenter-postgres pg_isready -U garfenter -d garfenter_tienda &> /dev/null; then
            print_step "PostgreSQL is ready"
            return 0
        fi

        attempt=$((attempt + 1))
        echo -ne "${YELLOW}[!]${NC} Waiting for database... ($attempt/$max_attempts)\r"
        sleep 2
    done

    echo ""
    print_error "PostgreSQL did not become ready in time"
    return 1
}

run_migrations() {
    print_info "Running database migrations..."

    # Use docker compose (v2) if available, otherwise docker-compose (v1)
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi

    $COMPOSE_CMD -f docker-compose.garfenter.yml exec -T garfenter-tienda python manage.py migrate

    print_step "Database migrations completed"
}

create_superuser_prompt() {
    echo ""
    print_info "To create an admin user, run:"
    echo -e "${CYAN}docker exec -it garfenter-tienda python manage.py createsuperuser${NC}"
    echo ""
}

print_access_info() {
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                     GARFENTER TIENDA IS READY!                        ║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Access URLs:${NC}"
    echo -e "  ${CYAN}API (GraphQL):${NC}      http://localhost:8000/graphql/"
    echo -e "  ${CYAN}Dashboard:${NC}          http://localhost:9000/"
    echo -e "  ${CYAN}Admin Panel:${NC}        http://localhost:8000/admin/"
    echo -e "  ${CYAN}Mailpit (Email):${NC}    http://localhost:8025/"
    echo ""
    echo -e "${GREEN}Service Status:${NC}"
    echo -e "  ${CYAN}API:${NC}                garfenter-tienda"
    echo -e "  ${CYAN}Worker:${NC}             garfenter-worker"
    echo -e "  ${CYAN}Dashboard:${NC}          garfenter-dashboard"
    echo -e "  ${CYAN}PostgreSQL:${NC}         garfenter-postgres"
    echo -e "  ${CYAN}Redis:${NC}              garfenter-redis"
    echo -e "  ${CYAN}Mailpit:${NC}            garfenter-mailpit"
    echo ""
    echo -e "${GREEN}Useful Commands:${NC}"
    echo -e "  ${CYAN}View logs:${NC}          docker logs -f garfenter-tienda"
    echo -e "  ${CYAN}Stop services:${NC}      docker-compose -f docker-compose.garfenter.yml down"
    echo -e "  ${CYAN}Restart services:${NC}   docker-compose -f docker-compose.garfenter.yml restart"
    echo -e "  ${CYAN}Create superuser:${NC}   docker exec -it garfenter-tienda python manage.py createsuperuser"
    echo -e "  ${CYAN}Shell access:${NC}       docker exec -it garfenter-tienda bash"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo -e "  ${CYAN}Currency:${NC}           GTQ (Quetzal Guatemalteco)"
    echo -e "  ${CYAN}Country:${NC}            Guatemala (GT)"
    echo -e "  ${CYAN}Language:${NC}           Spanish (es)"
    echo -e "  ${CYAN}Timezone:${NC}           America/Guatemala"
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_banner

    print_info "Starting Garfenter Tienda deployment..."
    echo ""

    check_dependencies
    create_env_file
    start_services

    if wait_for_db; then
        run_migrations
        create_superuser_prompt
        print_access_info

        print_step "Deployment completed successfully!"
        exit 0
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Run main function
main
