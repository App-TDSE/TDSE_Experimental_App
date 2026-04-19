#!/bin/bash

# Build script for all microservices

set -e

echo "Building TDSE Microservices..."
echo "=============================="

# Build common library
echo "Building common library..."
cd common-lib
mvn clean install -DskipTests
cd ..

# Build user service
echo "Building user service..."
cd user-service
mvn clean package -DskipTests
cd ..

# Build posts service
echo "Building posts service..."
cd posts-service
mvn clean package -DskipTests
cd ..

# Build stream service
echo "Building stream service..."
cd stream-service
mvn clean package -DskipTests
cd ..

echo ""
echo "=============================="
echo "Build complete!"
echo ""
echo "JAR files ready for deployment:"
echo "  - user-service/target/user-service.jar"
echo "  - posts-service/target/posts-service.jar"
echo "  - stream-service/target/stream-service.jar"
echo ""
echo "For local development:"
echo "  docker-compose up -d"
echo ""
echo "For AWS Lambda deployment:"
echo "  Read services/README.md for deployment instructions"
