#!/bin/bash
# Playground-optimized Cloud Build script
# Bypasses common permission issues in restricted environments

set -e

echo "🔧 Creating Cloud Build configuration for playground environment..."

# Check if PROJECT_ID is set
if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID not set. Please run: export PROJECT_ID=your-project-id"
    exit 1
fi

# Create cloudbuild.yaml with minimal permissions requirements
cat <<EOF > cloudbuild.yaml
steps:
  # Build the Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/\$PROJECT_ID/helloworld:latest', '.']
    dir: 'HelloWorldNodeJs'
  
  # Push to Container Registry (not Artifact Registry to avoid permission issues)
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/\$PROJECT_ID/helloworld:latest']

# Use shorter timeout for playground environments
timeout: '600s'

# Basic substitutions only
substitutions:
  _REGION: 'us-central1'

# Minimal options to avoid permission issues
options:
  logging: CLOUD_LOGGING_ONLY
  machineType: 'E2_STANDARD_4'
EOF

echo "✅ Created cloudbuild.yaml for playground environment"
echo "📋 Key differences from production version:"
echo "   - Uses Container Registry instead of Artifact Registry"
echo "   - Shorter timeout (10 minutes)"
echo "   - Minimal logging to avoid permission issues"
echo "   - Standard machine type to avoid quota issues"
echo ""
echo "🚀 To submit build: gcloud builds submit --config=cloudbuild.yaml HelloWorldNodeJs/"