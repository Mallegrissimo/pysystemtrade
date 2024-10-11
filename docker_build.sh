setup.sh
#!/bin/bash

# Source the .env file
if [ ! -f .env ]; then
    echo "Error: .env file not found."
    exit 1
fi
source .env

# Check if required variables are set
if [ -z "$COMPOSE_PROJECT_NAME" ]; then
    echo "Error: COMPOSE_PROJECT_NAME is not set in the .env file."
    # exit 1
    return
fi

if [ -z "$POSTGRES_PORT" ] || [ -z "$SSH_PORT" ]; then
    echo "Error: POSTGRES_PORT or SSH_PORT is not set in the .env file."
    return
fi

# Export the variables
export COMPOSE_PROJECT_NAME
export POSTGRES_PORT
export SSH_PORT

# Create a Docker network if it doesn't exist
NETWORK_NAME="${COMPOSE_PROJECT_NAME}_network"
if ! docker network inspect $NETWORK_NAME >/dev/null 2>&1; then
    echo "Creating Docker network: $NETWORK_NAME"
    docker network create $NETWORK_NAME
fi

# Run PostgreSQL container
POSTGRES_CONTAINER_NAME="${COMPOSE_PROJECT_NAME}_postgres"
if ! docker ps -a --format '{{.Names}}' | grep -q "^$POSTGRES_CONTAINER_NAME$"; then
    echo "Running PostgreSQL container: $POSTGRES_CONTAINER_NAME"
    docker run -d --name $POSTGRES_CONTAINER_NAME \
        --network $NETWORK_NAME \
        -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
        -p $POSTGRES_PORT:5432 \
        postgres
else
    echo "PostgreSQL container already exists: $POSTGRES_CONTAINER_NAME"
    docker start $POSTGRES_CONTAINER_NAME
fi

# Build the application Docker image
echo "Building Docker image for project: $COMPOSE_PROJECT_NAME"
docker build --build-arg PROJECT_NAME="$COMPOSE_PROJECT_NAME" -t "$COMPOSE_PROJECT_NAME" .

# Run the application container
APP_CONTAINER_NAME="${COMPOSE_PROJECT_NAME}_$(date +%s)"
echo "Running Docker container: $APP_CONTAINER_NAME"
docker run -d --name $APP_CONTAINER_NAME \
    --network $NETWORK_NAME \
    -p $SSH_PORT:22 \
    -e DB_HOST=$POSTGRES_CONTAINER_NAME \
    -e DB_PORT=5432 \
    -e DB_NAME=postgres \
    -e DB_USER=postgres \
    -e DB_PASSWORD=$POSTGRES_PASSWORD \
    "$COMPOSE_PROJECT_NAME"

echo "Application is running."
echo "SSH access: ssh root@localhost -p $SSH_PORT"
echo "PostgreSQL access from host: psql -h localhost -p $POSTGRES_PORT -U postgres"
echo "PostgreSQL access from app container: psql -h $POSTGRES_CONTAINER_NAME -U postgres"

