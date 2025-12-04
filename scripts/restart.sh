# Stop everything
docker compose down

# Wait 2 seconds
sleep 2

# Start fresh
docker compose up -d

# Wait for services to stabilize
sleep 10

# Check all containers are running
docker compose ps
