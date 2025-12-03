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

# Copy .env if not exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env from .env.example...${NC}"
    cp .env.example .env
else
    echo -e "${GREEN}.env already exists${NC}"
fi

# Load environment variables
source .env

echo -e "${YELLOW}Starting Docker containers...${NC}"
docker compose up -d

echo -e "${YELLOW}Waiting for services to be ready (10 seconds)...${NC}"
sleep 10

# Check if drupal directory exists
if [ ! -d "drupal" ]; then
    echo -e "${YELLOW}Installing Drupal codebase with Composer...${NC}"
    echo -e "${YELLOW}This may take 2-3 minutes...${NC}"
    composer create-project drupal/recommended-project:11.2.8 drupal
    echo -e "${GREEN}Drupal codebase installed successfully${NC}"
else
    echo -e "${GREEN}Drupal directory already exists, skipping composer create-project${NC}"
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${YELLOW}Access your services at:${NC}"
echo -e "  ${GREEN}Drupal:${NC}        http://drupal.localhost:${HTTP_PORT:-8060}"
echo -e "  ${GREEN}phpMyAdmin:${NC}    http://pma.localhost:${HTTP_PORT:-8060}"
echo -e "  ${GREEN}Mailhog:${NC}       http://mail.localhost:${HTTP_PORT:-8060}"
echo -e "  ${GREEN}Traefik:${NC}       http://localhost:${TRAEFIK_DASHBOARD_PORT:-8080}"
echo ""
