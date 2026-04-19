#!/bin/bash

# Deploy to AWS Lambda using Serverless Framework

set -e

if [ $# -eq 0 ]; then
    echo "Usage: ./deploy.sh <service> [aws-region]"
    echo ""
    echo "Services: user-service, posts-service, stream-service, all"
    echo "AWS Region: default is us-east-1"
    exit 1
fi

SERVICE=$1
REGION=${2:-us-east-1}

export AWS_REGION=$REGION

deploy_service() {
    local service_name=$1
    local service_dir=$1
    
    echo "Deploying $service_name to AWS Lambda in $REGION..."
    
    cd $service_dir
    
    if [ ! -f "serverless.yml" ]; then
        echo "ERROR: serverless.yml not found in $service_dir"
        exit 1
    fi
    
    # Build the service
    echo "Building $service_name..."
    mvn clean package -DskipTests
    
    # Deploy
    echo "Deploying $service_name..."
    serverless deploy --region $REGION
    
    echo "$service_name deployed successfully!"
    cd ..
}

case $SERVICE in
    user-service)
        deploy_service user-service
        ;;
    posts-service)
        deploy_service posts-service
        ;;
    stream-service)
        deploy_service stream-service
        ;;
    all)
        deploy_service user-service
        deploy_service posts-service
        deploy_service stream-service
        echo "All services deployed successfully!"
        ;;
    *)
        echo "ERROR: Unknown service '$SERVICE'"
        echo "Services: user-service, posts-service, stream-service, all"
        exit 1
        ;;
esac
