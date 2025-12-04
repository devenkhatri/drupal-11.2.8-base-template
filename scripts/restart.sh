# Stop everything
# docker compose down

# Wait 2 seconds
# sleep 2

# Start fresh
# docker compose up -d

# Wait for services to stabilize
# sleep 15

docker compose down && sleep 2 && docker compose up -d && sleep 15