#!/bin/bash

# Build Lambda container images and push to ECR

set -e

if [ $# -lt 2 ]; then
    echo "Usage: ./push-to-ecr.sh <aws-account-id> <aws-region> [services]"
    echo ""
    echo "Services: user-service, posts-service, stream-service (default: all)"
    echo ""
    echo "Example: ./push-to-ecr.sh 123456789012 us-east-1"
    exit 1
fi

AWS_ACCOUNT_ID=$1
AWS_REGION=$2
SERVICES=${3:-all}

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

push_image() {
    local service_name=$1
    local repo_name=$1
    
    echo ""
    echo "Building and pushing $service_name to ECR..."
    
    cd $service_name
    
    # Build the JAR
    mvn clean package -DskipTests
    
    # Build Docker image for Lambda
    local image_uri="${ECR_REGISTRY}/${repo_name}:latest"
    echo "Building Docker image: $image_uri"
    docker build -f Dockerfile -t $image_uri .
    
    # Push to ECR
    echo "Pushing to ECR..."
    docker push $image_uri
    
    echo "$service_name pushed successfully!"
    echo "Image: $image_uri"
    
    cd ..
}

case $SERVICES in
    all)
        # Create ECR repositories if they don't exist
        for repo in user-service posts-service stream-service; do
            aws ecr describe-repositories --repository-names $repo --region $AWS_REGION 2>/dev/null || \
            aws ecr create-repository --repository-name $repo --region $AWS_REGION
        done
        
        push_image user-service
        push_image posts-service
        push_image stream-service
        ;;
    *)
        push_image $SERVICES
        ;;
esac

echo ""
echo "======================================"
echo "Images pushed to ECR successfully!"
echo "ECR Registry: $ECR_REGISTRY"
echo ""
echo "You can now deploy to Lambda using:"
echo "  serverless deploy"
