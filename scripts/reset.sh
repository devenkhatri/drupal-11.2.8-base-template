#!/bin/bash
# Reset script - removes containers, volumes, and drupal codebase

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${RED}========== RESET WARNING ==========${NC}"
echo -e "${RED}This will:${NC}"
echo "  - Stop all Docker containers"
echo "  - Delete the database volume (all data lost)"
echo "  - Remove the Drupal codebase"
echo ""
echo -e "${RED}This action CANNOT be undone!${NC}"
echo -e "${RED}===================================${NC}"
echo ""

read -p "Are you absolutely sure? Type 'yes' to confirm: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}Reset cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Stopping containers and removing volumes...${NC}"
docker compose down -v

echo -e "${YELLOW}Removing Drupal codebase...${NC}"
rm -rf drupal

echo -e "${GREEN}Reset complete!${NC}"
echo ""
echo -e "${YELLOW}To reinstall, run:${NC}"
echo "  ./scripts/install.sh"
