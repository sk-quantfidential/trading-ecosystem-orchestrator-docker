#!/bin/bash

# Build script for audit-correlator service
# This script builds the Docker image for the audit-correlator service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="audit-correlator"
IMAGE_TAG="latest"
SERVICE_DIR="../audit-correlator-go"
DOCKERFILE_PATH="$SERVICE_DIR/Dockerfile"

echo -e "${BLUE}Building audit-correlator service...${NC}"

# Check if the service directory exists
if [ ! -d "$SERVICE_DIR" ]; then
    echo -e "${RED}Error: Service directory $SERVICE_DIR not found${NC}"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo -e "${RED}Error: Dockerfile not found at $DOCKERFILE_PATH${NC}"
    exit 1
fi

# Change to the service directory
cd "$SERVICE_DIR"

echo -e "${YELLOW}Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"

# Build the Docker image
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully built ${IMAGE_NAME}:${IMAGE_TAG}${NC}"

    # Show image info
    echo -e "${BLUE}Image details:${NC}"
    docker images "${IMAGE_NAME}:${IMAGE_TAG}"
else
    echo -e "${RED}Failed to build ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
    exit 1
fi

echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${YELLOW}You can now run: docker-compose up -d audit-correlator${NC}"