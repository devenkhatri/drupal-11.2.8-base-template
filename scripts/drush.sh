#!/bin/bash
# Drush wrapper script - runs drush inside the PHP container
docker compose run --rm php vendor/bin/drush "$@"
