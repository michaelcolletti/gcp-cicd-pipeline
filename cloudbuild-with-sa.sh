#!/bin/bash
# Cloud Build configuration with Service Account authentication
# Creates a build configuration that uses service account credentials

set -e

echo "🔧 Creating Cloud Build configuration with Service Account"
echo "========================================================="

# Check if service account key exists
KEY_FILE="./service-account-key.json"
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Service account key not found: $KEY_FILE"
    echo "Please run ./service-account-setup.sh first"
    exit 1
fi

# Extract project ID from service account key
PROJECT_ID=$(cat $KEY_FILE | grep -o '"project_id": "[^"]*' | cut -d'"' -f4)
echo "📋 Using project: $PROJECT_ID"

# Create Cloud Build configuration with service account
cat <<EOF > cloudbuild-sa.yaml
steps:
  # Step 1: Authenticate with service account
  - name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'bash'
    args:
    - '-c'
    - |
      echo "🔐 Authenticating with service account..."
      gcloud auth activate-service-account --key-file=/workspace/service-account-key.json
      gcloud config set project $PROJECT_ID
      echo "✅ Authentication successful"
      gcloud auth list

  # Step 2: Build the Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/helloworld:\$BUILD_ID', '-t', 'gcr.io/$PROJECT_ID/helloworld:latest', '.']
    dir: 'HelloWorldNodeJs'

  # Step 3: Push to Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/helloworld:\$BUILD_ID']

  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/helloworld:latest']

  # Step 4: Deploy to GKE (optional)
  - name: 'gcr.io/cloud-builders/kubectl'
    args:
    - 'set'
    - 'image'
    - 'deployment/helloworld'
    - 'helloworld=gcr.io/$PROJECT_ID/helloworld:\$BUILD_ID'
    env:
    - 'CLOUDSDK_COMPUTE_ZONE=us-central1-b'
    - 'CLOUDSDK_CONTAINER_CLUSTER=playground-cluster'

# Build options
options:
  logging: CLOUD_LOGGING_ONLY
  machineType: 'E2_STANDARD_4'
  
# Timeout
timeout: '1200s'

# Substitutions
substitutions:
  _REGION: 'us-central1'
  _ZONE: 'us-central1-b'
EOF

echo "✅ Created cloudbuild-sa.yaml"
echo ""
echo "🚀 To submit build with service account:"
echo "gcloud builds submit --config=cloudbuild-sa.yaml ."
echo ""
echo "💡 Note: The service account key will be automatically used during the build"