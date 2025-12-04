#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Drupal WSL2 + Docker Setup${NC}"
echo -e "${GREEN}======================================${NC}"

# Ensure running inside project root
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ ERROR: Please run this script from the project root directory."
    exit 1
fi
# Verify the file was created correctly
echo "✓ File created. Checking syntax..."
docker-compose config > /dev/null && echo "✓ YAML syntax is valid!" || echo "✗ Error in YAML"

# Copy .env if not exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env from .env.example...${NC}"
    cp .env.example .env
else
    echo -e "${GREEN}.env file already exists, skipping copy.${NC}"
fi

# Load environment variables
source .env

echo -e "${YELLOW}Starting Docker containers...${NC}"
docker compose up -d

echo -e "${YELLOW}Waiting for services to be ready (10 seconds)...${NC}"
sleep 10

# Ensure composer exists in system
if ! command -v composer &> /dev/null; then
    echo "❌ ERROR: Composer is not installed."
    echo "Install with: sudo apt install composer"
    exit 1
fi

# Check if drupal directory exists
if [ ! -d "drupal" ] || [ -z "$(ls -A drupal 2>/dev/null)" ]; then
    echo -e "${YELLOW}Installing Drupal codebase with Composer...${NC}"
    echo -e "${YELLOW}This may take 2-3 minutes...${NC}"
    composer create-project drupal/recommended-project:11.2.8 drupal
    echo -e "${GREEN}Drupal codebase installed successfully${NC}"
else
    echo -e "${GREEN}Drupal directory already exists, skipping composer create-project${NC}"
fi

echo -e "${YELLOW}Setting permissions...${NC}"
chmod -R 775 drupal
# chown -R www-data:www-data drupal || true
# 1. Add yourself to docker group
# usermod -aG docker $USER

# 2. Apply changes to current session
# newgrp docker

# 3. Fix socket ownership
# chown root:docker /var/run/docker.sock

# 4. Fix socket permissions
# chmod 660 /var/run/docker.sock

# Docker service restart    
echo -e "${GREEN}Permissions set successfully. Now restarting the services...${NC}"
# Restart Docker containers to apply any changes
echo -e "${RED}Stopping Docker containers...${NC}"
docker compose down
sleep 2
echo -e "${YELLOW}Starting Docker containers...${NC}"
docker compose up -d
echo -e "${YELLOW}Waiting for services to be ready (10 seconds)...${NC}"
sleep 10

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${YELLOW}Access your services at:${NC}"
echo -e "  ${GREEN}Drupal:${NC}        http://drupal.localhost:${HTTP_PORT:-80}"
echo -e "  ${GREEN}phpMyAdmin:${NC}    http://pma.localhost:${HTTP_PORT:-80}"
echo -e "  ${GREEN}Mailhog:${NC}       http://mail.localhost:${HTTP_PORT:-80}"
echo -e "  ${GREEN}Traefik:${NC}       http://localhost:${TRAEFIK_DASHBOARD_PORT:-8080}"
echo ""
echo "Next step: Run the Drupal installer in the browser."
echo ""
