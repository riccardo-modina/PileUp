#!/bin/bash

echo "Setting up PileUp..."

# download docker-compose.yaml
curl -s -O https://raw.githubusercontent.com/GodzillaWasTaken/PileUp/main/docker-compose.yaml

# download .env only if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env from example..."
    curl -s -o .env https://raw.githubusercontent.com/GodzillaWasTaken/PileUp/main/.env_example
else
    echo ".env already exists, skipping download to protect your secrets."
fi

echo "Files ready!"
echo "------------------------------------------"
echo "Next steps:"
echo "1. Open the '.env' file and fill in your database passwords."
echo "2. Run: docker compose up -d"
echo "3. Visit: http://localhost:5173"
echo "------------------------------------------"