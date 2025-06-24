#!/bin/bash
# Simplified deployment script for playground environments
# Focuses on manual deployment steps when Cloud Deploy permissions are limited

set -e

echo "🚀 Playground Deployment Script"
echo "==============================================="

# Check prerequisites
if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID not set. Please run: export PROJECT_ID=your-project-id"
    exit 1
fi

echo "📋 This script will guide you through manual deployment steps"
echo "   when Cloud Deploy permissions are restricted."
echo ""

# Step 1: Check if image exists
echo "🔍 Step 1: Checking if container image exists..."
if gcloud container images list --repository=gcr.io/$PROJECT_ID --filter="name:helloworld" --format="value(name)" | grep -q helloworld; then
    echo "✅ Container image found: gcr.io/$PROJECT_ID/helloworld"
else
    echo "❌ Container image not found. Please run cloudbuild first:"
    echo "   gcloud builds submit --config=cloudbuild.yaml HelloWorldNodeJs/"
    exit 1
fi

# Step 2: Create GKE cluster (if needed)
echo ""
echo "🔧 Step 2: Setting up GKE cluster..."
CLUSTER_NAME="playground-cluster"
ZONE="us-central1-b"

if gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID >/dev/null 2>&1; then
    echo "✅ Cluster $CLUSTER_NAME already exists"
else
    echo "🆕 Creating cluster $CLUSTER_NAME..."
    gcloud container clusters create $CLUSTER_NAME \
        --zone=$ZONE \
        --project=$PROJECT_ID \
        --num-nodes=1 \
        --machine-type=e2-medium \
        --enable-autoscaling \
        --min-nodes=1 \
        --max-nodes=3 \
        --enable-autorepair \
        --enable-autoupgrade
fi

# Step 3: Get credentials
echo ""
echo "🔑 Step 3: Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID

# Step 4: Create deployment
echo ""
echo "📦 Step 4: Creating Kubernetes deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld
  labels:
    app: helloworld
spec:
  replicas: 2
  selector:
    matchLabels:
      app: helloworld
  template:
    metadata:
      labels:
        app: helloworld
    spec:
      containers:
      - name: helloworld
        image: gcr.io/$PROJECT_ID/helloworld:latest
        ports:
        - containerPort: 8080
        env:
        - name: TARGET
          value: "Playground Environment"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: helloworld-service
spec:
  selector:
    app: helloworld
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
EOF

# Step 5: Wait for deployment
echo ""
echo "⏳ Step 5: Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/helloworld

# Step 6: Get service URL
echo ""
echo "🌐 Step 6: Getting service URL..."
echo "⏳ Waiting for LoadBalancer IP (this may take a few minutes)..."

# Wait for external IP
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get service helloworld-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
        break
    fi
    echo "   Waiting for external IP... (attempt $i/30)"
    sleep 10
done

if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
    echo "✅ Application deployed successfully!"
    echo "🌐 Access your application at: http://$EXTERNAL_IP"
    echo ""
    echo "🧪 Test with: curl http://$EXTERNAL_IP"
else
    echo "⚠️  LoadBalancer IP not ready yet. Check status with:"
    echo "   kubectl get service helloworld-service"
fi

echo ""
echo "📊 Deployment status:"
kubectl get pods -l app=helloworld
kubectl get service helloworld-service