#!/bin/bash
# Minimal API enablement script for playground environments
# Skips IAM-heavy operations that may fail in restricted environments

echo "Enabling required GCP services..."

# Enable core services without IAM dependencies
gcloud services enable \
  container.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  clouddeploy.googleapis.com \
  --project=$PROJECT_ID

echo "Core services enabled successfully!"
echo ""
echo "Note: Some services may already be enabled in playground environments."
echo "If you encounter permission errors, your account may have restricted IAM access."