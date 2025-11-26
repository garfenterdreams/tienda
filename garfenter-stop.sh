#!/bin/bash

# =============================================================================
# GARFENTER TIENDA - Stop Script
# =============================================================================
# Gracefully stops all Garfenter Tienda services
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║              GARFENTER TIENDA - Stopping Services                     ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Determine Docker Compose command
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

print_banner
print_info "Stopping Garfenter Tienda services..."
echo ""

# Stop services
$COMPOSE_CMD -f docker-compose.garfenter.yml down

print_step "All services stopped"
echo ""
print_info "Services stopped. Data is preserved in Docker volumes."
print_info "To start again, run: ./garfenter-start.sh"
echo ""
print_warning "To remove all data (including database), run:"
echo -e "  ${CYAN}docker-compose -f docker-compose.garfenter.yml down -v${NC}"
echo ""
