#!/usr/bin/env bats

# Setup function run before each test
setup() {
  export PROJECT_ID="test-project-id"
  export ZONE="us-east1-a"
  # Create temp directory for test outputs
  export TEST_TEMP_DIR="$(mktemp -d)"
  cd "$TEST_TEMP_DIR"
}

# Teardown function run after each test
teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

@test "enable-apis.sh creates proper gcloud command" {
  # Copy the script to temp directory
  cp "${BATS_TEST_DIRNAME}/../enable-apis.sh" .
  
  # Mock gcloud command
  function gcloud() {
    echo "gcloud $@" >> gcloud_calls.log
    return 0
  }
  export -f gcloud
  
  # Run the script
  bash enable-apis.sh
  
  # Verify gcloud services enable was called with correct services
  run cat gcloud_calls.log
  [[ "$output" == *"services enable"* ]]
  [[ "$output" == *"serviceusage.googleapis.com"* ]]
  [[ "$output" == *"container.googleapis.com"* ]]
  [[ "$output" == *"cloudbuild.googleapis.com"* ]]
  [[ "$output" == *"clouddeploy.googleapis.com"* ]]
}

@test "cloudbuild.sh generates valid cloudbuild.yaml" {
  cp "${BATS_TEST_DIRNAME}/../cloudbuild.sh" .
  
  # Run the script
  bash cloudbuild.sh
  
  # Verify cloudbuild.yaml was created
  [ -f "cloudbuild.yaml" ]
  
  # Verify it contains expected Docker build steps
  run cat cloudbuild.yaml
  [[ "$output" == *"gcr.io/cloud-builders/docker"* ]]
  [[ "$output" == *"gcr.io/\$PROJECT_ID/helloworld"* ]]
  [[ "$output" == *"beta deploy releases create"* ]]
}

@test "clouddeploy.sh generates valid clouddeploy.yaml" {
  cp "${BATS_TEST_DIRNAME}/../clouddeploy.sh" .
  
  # Run the script
  bash clouddeploy.sh
  
  # Verify clouddeploy.yaml was created
  [ -f "clouddeploy.yaml" ]
  
  # Verify it contains the three environments
  run cat clouddeploy.yaml
  [[ "$output" == *"name: dev"* ]]
  [[ "$output" == *"name: staging"* ]]
  [[ "$output" == *"name: prod"* ]]
  [[ "$output" == *"requireApproval: true"* ]]
}

@test "skaffold.sh generates valid skaffold.yaml" {
  cp "${BATS_TEST_DIRNAME}/../skaffold.sh" .
  
  # Run the script
  bash skaffold.sh
  
  # Verify skaffold.yaml was created
  [ -f "skaffold.yaml" ]
  
  # Verify it references kubernetes-app.yaml
  run cat skaffold.yaml
  [[ "$output" == *"kubernetes-app.yaml"* ]]
  [[ "$output" == *"apiVersion: skaffold/"* ]]
}

@test "create-manifest.sh generates valid kubernetes manifest" {
  cp "${BATS_TEST_DIRNAME}/../create-manifest.sh" .
  
  # Run the script
  bash create-manifest.sh
  
  # Verify kubernetes-app.yaml was created
  [ -f "kubernetes-app.yaml" ]
  
  # Verify it contains deployment and service
  run cat kubernetes-app.yaml
  [[ "$output" == *"kind: Deployment"* ]]
  [[ "$output" == *"kind: Service"* ]]
  [[ "$output" == *"hello-world-demo"* ]]
  [[ "$output" == *"replicas: 3"* ]]
}

@test "deploy.sh sets correct environment variables" {
  cp "${BATS_TEST_DIRNAME}/../deploy.sh" .
  
  # Mock gcloud commands
  function gcloud() {
    if [[ "$1" == "config" ]]; then
      echo "test-project-123"
    else
      echo "gcloud $@" >> gcloud_calls.log
    fi
    return 0
  }
  export -f gcloud
  
  # Run the script
  bash deploy.sh
  
  # Verify gcloud deploy apply was called
  run cat gcloud_calls.log
  [[ "$output" == *"beta deploy apply"* ]]
  [[ "$output" == *"--file clouddeploy.yaml"* ]]
  [[ "$output" == *"--region=us-central1"* ]]
}

@test "pipeline scripts handle missing PROJECT_ID gracefully" {
  unset PROJECT_ID
  cp "${BATS_TEST_DIRNAME}/../cloudbuild.sh" .
  
  # Mock gcloud to return empty project
  function gcloud() {
    if [[ "$1" == "config" ]]; then
      echo ""
    fi
    return 0
  }
  export -f gcloud
  
  # Run the script - should still work with empty PROJECT_ID
  run bash cloudbuild.sh
  [ "$status" -eq 0 ]
}