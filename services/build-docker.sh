#!/bin/bash

# Build Docker images for local development

set -e

echo "Building Docker images for local development..."
echo "==============================================="

# Build user service
echo "Building user service Docker image..."
cd user-service
docker build -f Dockerfile.dev -t tdse-user-service:latest .
cd ..

# Build posts service
echo "Building posts service Docker image..."
cd posts-service
docker build -f Dockerfile.dev -t tdse-posts-service:latest .
cd ..

# Build stream service
echo "Building stream service Docker image..."
cd stream-service
docker build -f Dockerfile.dev -t tdse-stream-service:latest .
cd ..

echo ""
echo "==============================================="
echo "Docker images built successfully!"
echo ""
echo "Image names:"
echo "  - tdse-user-service:latest"
echo "  - tdse-posts-service:latest"
echo "  - tdse-stream-service:latest"
echo ""
echo "Start all services with:"
echo "  docker-compose up -d"
