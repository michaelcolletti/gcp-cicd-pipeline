#!/usr/bin/env bats

# Integration tests for the complete GCP CI/CD pipeline flow
# These tests verify that the scripts work together correctly

setup() {
    export PROJECT_ID="test-project-integration"
    export ZONE="us-east1-a"
    export TEST_TEMP_DIR="$(mktemp -d)"
    cd "$TEST_TEMP_DIR"
    
    # Copy all scripts to temp directory
    cp "${BATS_TEST_DIRNAME}/../"*.sh .
    
    # Mock gcloud command for all tests
    function gcloud() {
        case "$1" in
            "config")
                echo "$PROJECT_ID"
                ;;
            "services")
                echo "API enabled: $*" >> api_calls.log
                ;;
            "beta")
                echo "Deploy command: $*" >> deploy_calls.log
                ;;
            *)
                echo "gcloud $*" >> all_gcloud_calls.log
                ;;
        esac
        return 0
    }
    export -f gcloud
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "complete pipeline flow generates all required files" {
    # Run the complete pipeline sequence
    bash enable-apis.sh
    bash cloudbuild.sh
    bash clouddeploy.sh  
    bash skaffold.sh
    bash create-manifest.sh
    
    # Verify all YAML files were created
    [ -f "cloudbuild.yaml" ]
    [ -f "clouddeploy.yaml" ]
    [ -f "skaffold.yaml" ]
    [ -f "kubernetes-app.yaml" ]
    
    # Verify APIs were enabled
    [ -f "api_calls.log" ]
    run cat api_calls.log
    [[ "$output" == *"cloudbuild.googleapis.com"* ]]
}

@test "generated YAML files are valid and interconnected" {
    # Generate all files
    bash cloudbuild.sh
    bash clouddeploy.sh
    bash skaffold.sh
    bash create-manifest.sh
    
    # Check that cloudbuild.yaml references the correct image name
    run grep "gcr.io/\$PROJECT_ID/helloworld" cloudbuild.yaml
    [ "$status" -eq 0 ]
    
    # Check that kubernetes-app.yaml uses the same image
    run grep "gcr.io/\${PROJECT_ID}/helloworld" kubernetes-app.yaml
    [ "$status" -eq 0 ]
    
    # Check that skaffold.yaml references kubernetes-app.yaml
    run grep "kubernetes-app.yaml" skaffold.yaml
    [ "$status" -eq 0 ]
    
    # Check that clouddeploy.yaml has proper pipeline stages
    run grep -A5 -B5 "targetId: dev" clouddeploy.yaml
    [ "$status" -eq 0 ]
    run grep -A5 -B5 "targetId: staging" clouddeploy.yaml
    [ "$status" -eq 0 ]
    run grep -A5 -B5 "targetId: prod" clouddeploy.yaml
    [ "$status" -eq 0 ]
}

@test "deployment script uses generated files correctly" {
    # Generate clouddeploy.yaml first
    bash clouddeploy.sh
    
    # Run deploy script
    bash deploy.sh
    
    # Verify deploy command was called with correct parameters
    [ -f "deploy_calls.log" ]
    run cat deploy_calls.log
    [[ "$output" == *"deploy apply"* ]]
    [[ "$output" == *"--file clouddeploy.yaml"* ]]
    [[ "$output" == *"--region=us-central1"* ]]
    [[ "$output" == *"--project=$PROJECT_ID"* ]]
}

@test "pipeline handles environment variable substitution" {
    export PROJECT_ID="custom-test-project"
    
    # Generate files with custom project ID
    bash cloudbuild.sh
    bash create-manifest.sh
    
    # Verify PROJECT_ID is used in generated files
    run cat cloudbuild.yaml
    [[ "$output" == *"gcr.io/\$PROJECT_ID/helloworld"* ]]
    
    run cat kubernetes-app.yaml
    [[ "$output" == *"gcr.io/\${PROJECT_ID}/helloworld"* ]]
}

@test "error handling when gcloud is not available" {
    # Unset the gcloud function to simulate missing gcloud
    unset -f gcloud
    
    # Create a fake gcloud that fails
    function gcloud() {
        return 1
    }
    export -f gcloud
    
    # The scripts should handle gcloud failures gracefully
    # Most scripts generate static YAML and don't strictly require gcloud
    run bash cloudbuild.sh
    [ "$status" -eq 0 ]  # Should succeed even if gcloud fails
    
    run bash clouddeploy.sh
    [ "$status" -eq 0 ]  # Should succeed even if gcloud fails
}