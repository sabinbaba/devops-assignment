#!/bin/bash
set -e

# ============================
# Bash CI/CD Script
# Node.js + Minikube Deployment
# ============================

echo "Checking Minikube status..."

if ! minikube status | grep -q "Running"; then
    echo "Starting Minikube..."
    minikube start --driver=docker
else
    echo "Minikube is already running."
fi

# -----------------------------------
# Set Docker Env to Minikube
# -----------------------------------

echo "Switching Docker to Minikube environment..."
eval $(minikube docker-env)

# -----------------------------------
# Build Docker Image
# -----------------------------------

IMAGE_NAME="class-btech:dev"
echo "Building Docker image: $IMAGE_NAME"

if ! docker build -t "$IMAGE_NAME" .; then
    echo "ERROR: Failed to build Docker image!"
    exit 1
fi

# -----------------------------------
# Update deployment.yaml Image
# -----------------------------------

echo "Updating deployment.yaml with image $IMAGE_NAME ..."

if [[ -f "deployment.yaml" ]]; then
    sed -i "s|image: .*|image: $IMAGE_NAME|g" deployment.yaml
else
    echo "ERROR: deployment.yaml not found!"
    exit 1
fi

# -----------------------------------
# Apply Kubernetes YAML Files
# -----------------------------------

echo "Applying Kubernetes files..."

if ! kubectl apply -f deployment.yaml --validate=false; then
    echo "ERROR: Failed to apply deployment.yaml!"
    exit 1
fi

if ! kubectl apply -f service.yaml --validate=false; then
    echo "ERROR: Failed to apply service.yaml!"
    exit 1
fi

# -----------------------------------
# Restart Deployment
# -----------------------------------

echo "Restarting deployment..."
kubectl rollout restart deployment/node-deployment

# -----------------------------------
# Show Status
# -----------------------------------

sleep 3

echo "Deployment status:"
kubectl get pods -o wide

echo ""
echo "Service info:"
kubectl get svc

echo ""
echo "🎉 CI/CD Deployment completed successfully!"
