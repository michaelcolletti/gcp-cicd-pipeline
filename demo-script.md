# GCP CI/CD Pipeline Demo Script

This script provides a step-by-step walkthrough for demonstrating the GCP CI/CD pipeline in a Loom recording.

## Pre-Demo Setup (Do this before recording)

1. **Set up GCP Project**
   ```bash
   export PROJECT_ID="your-demo-project-id"
   export ZONE="us-east1-a"
   gcloud config set project $PROJECT_ID
   ```

2. **Verify Prerequisites**
   ```bash
   # Check gcloud is authenticated
   gcloud auth list
   
   # Check billing is enabled
   gcloud billing accounts list
   
   # Check Docker is running
   docker version
   ```

## Demo Script (15-20 minutes)

### Introduction (2 minutes)
"Today I'll demonstrate a complete CI/CD pipeline on Google Cloud Platform that automatically builds, tests, and deploys applications across multiple environments."

**Show:** Repository structure in file explorer
```bash
tree -L 2 .
```

### Step 1: Environment Setup (3 minutes)

**Narrate:** "First, let's set up our environment variables and enable the required GCP APIs"

```bash
# Show current directory
pwd
ls -la

# Set environment variables
export PROJECT_ID="your-demo-project-id"
export ZONE="us-east1-a"
echo "Project ID: $PROJECT_ID"
echo "Zone: $ZONE"

# Enable required APIs
./enable-apis.sh
```

**Show:** The APIs being enabled in the console output

### Step 2: Create Build Pipeline (3 minutes)

**Narrate:** "Now let's create our Cloud Build configuration that will build our Docker image and push it to Artifact Registry"

```bash
# Generate Cloud Build configuration
./cloudbuild.sh

# Show the generated file
cat cloudbuild.yaml
```

**Highlight:** 
- Docker build step
- Artifact Registry push
- Cloud Deploy release creation

### Step 3: Create Deployment Pipeline (3 minutes)

**Narrate:** "Next, we'll create our deployment pipeline with three environments: dev, staging, and production"

```bash
# Generate Cloud Deploy configuration
./clouddeploy.sh

# Show the generated pipeline
cat clouddeploy.yaml
```

**Highlight:**
- Three deployment targets
- Automatic promotion dev → staging
- Manual approval for production

### Step 4: Configure Skaffold (2 minutes)

**Narrate:** "Skaffold will manage our Kubernetes deployments declaratively"

```bash
# Generate Skaffold configuration
./skaffold.sh

# Show the configuration
cat skaffold.yaml
```

### Step 5: Create Kubernetes Manifests (2 minutes)

**Narrate:** "Let's create our Kubernetes deployment and service configurations"

```bash
# Generate Kubernetes manifests
./create-manifest.sh

# Show the manifests
cat kubernetes-app.yaml
```

**Highlight:**
- Deployment configuration
- LoadBalancer service
- Environment variable injection

### Step 6: Deploy the Pipeline (3 minutes)

**Narrate:** "Now let's deploy our complete pipeline to Google Cloud"

```bash
# Deploy the pipeline
./deploy.sh

# Check the deployment status
gcloud deploy delivery-pipelines list --region=us-central1
```

**Show:** Switch to GCP Console to show:
- Cloud Build triggers
- Cloud Deploy pipeline
- GKE clusters

### Step 7: Demonstrate the Pipeline (2 minutes)

**Narrate:** "Let's trigger a deployment by making a code change"

```bash
# Navigate to the sample app
cd HelloWorldNodeJs

# Show the current app
cat index.js

# Make a small change
sed -i 's/Hello World!/Hello GCP CI\/CD Pipeline!/' index.js

# Commit and push (if connected to repo)
git add .
git commit -m "Update greeting message"
git push origin main
```

**Show:** In GCP Console:
- Cloud Build running
- Deployment progressing through stages
- Application running in dev environment

### Wrap-up (1 minute)

**Narrate:** "We've successfully created a complete CI/CD pipeline that automatically builds, tests, and deploys applications across multiple environments with approval gates."

**Summary points:**
- Automated Docker builds
- Multi-environment deployments
- Infrastructure as code
- Built-in approval workflows

## Post-Demo Cleanup

```bash
# Clean up resources (optional)
gcloud deploy delivery-pipelines delete my-demo-app-1 --region=us-central1 --force
gcloud container clusters delete dev-cluster --zone=us-central1-b --quiet
gcloud container clusters delete staging-cluster --zone=us-central1-b --quiet  
gcloud container clusters delete prod-cluster --zone=us-central1-b --quiet
```

## Demo Tips

### Speaking Points
- **Emphasize:** "Everything is generated from shell scripts - no manual YAML editing"
- **Highlight:** "Production deployments require manual approval for safety"
- **Explain:** "This pattern scales to any application - just replace the sample app"

### Common Issues During Demo
1. **API quotas:** Pre-enable APIs before recording
2. **Cluster creation time:** Consider pre-creating clusters
3. **Network issues:** Have backup slides ready

### Visual Aids
- Keep GCP Console open in another tab
- Use `clear` command between major steps
- Use `echo` commands to show progress
- Highlight important sections in generated files

### Time Management
- **Practice run:** 12-15 minutes without narration
- **Buffer time:** Allow 5 minutes for unexpected delays
- **Key message:** Focus on automation and best practices

## Alternative Short Demo (5 minutes)

If time is limited, focus on:
1. Show repository structure (30 seconds)
2. Run `./enable-apis.sh` (1 minute)
3. Run all pipeline scripts in sequence (2 minutes)
4. Show generated files (1 minute)
5. Quick GCP Console tour (30 seconds)

## Troubleshooting During Demo

### If Commands Fail
- Have backup pre-generated files ready
- Switch to "explain the concept" mode
- Use screenshots of successful runs

### If Internet is Slow
- Pre-download any dependencies
- Use local docker builds first
- Have offline slides as backup

## Post-Demo Q&A Prep

**Expected Questions:**
- "How do you handle secrets?" → Show Cloud Build substitutions
- "What about testing?" → Mention the BATS test suite
- "Can this work with other cloud providers?" → Discuss Terraform alternatives
- "How do you handle rollbacks?" → Show Cloud Deploy rollback features