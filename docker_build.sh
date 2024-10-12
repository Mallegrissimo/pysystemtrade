#!/bin/bash

# Load environment variables
source .env

# Define image and container names
IMAGE_NAME="${PROJECT_NAME}_image"
CONTAINER_NAME="${PROJECT_NAME}_container"

# Build the Docker image
docker build \
    --build-arg ROOT_PASSWORD=$ROOT_PASSWORD \
    --build-arg PROJECT_NAME=$PROJECT_NAME \
    --build-arg MONGO_INITDB_ROOT_PASSWORD=$MONGO_INITDB_ROOT_PASSWORD \
    --build-arg MONGO_INITDB_ROOT_USERNAME=$MONGO_INITDB_ROOT_USERNAME \
    -t $IMAGE_NAME .

# Run the Docker container
docker run -d \
    --name $CONTAINER_NAME \
    -p ${MONGO_PORT}:27017 \
    -p ${SSH_PORT}:22 \
    --add-host=host.docker.internal:host-gateway \
    -e PROJECT_NAME=$PROJECT_NAME \
    -e ROOT_PASSWORD=$ROOT_PASSWORD \
    -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_INITDB_ROOT_PASSWORD \
    -e MONGO_INITDB_ROOT_USERNAME=$MONGO_INITDB_ROOT_USERNAME \
    $IMAGE_NAME

WORKDIR /app

echo "MongoDB container is running. You can connect to it using:"
echo "  - MongoDB: localhost:${MONGO_PORT}"
echo "  - SSH: ssh -p ${SSH_PORT} root@localhost (password: $ROOT_PASSWORD)"
echo "  - Interactive Broker Gateway: Use host.docker.internal:4001 from within the container"
echo ""
echo "Image name: $IMAGE_NAME"
echo "Container name: $CONTAINER_NAME"