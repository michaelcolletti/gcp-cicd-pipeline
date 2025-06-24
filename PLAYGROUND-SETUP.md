# GCP Playground Environment Setup Guide

This guide helps you set up the CI/CD pipeline in restricted playground environments where you may not have full IAM permissions.

## Quick Start for Playground Environments

### Prerequisites
```bash
# Set your project ID (replace with your actual project ID)
export PROJECT_ID="playground-s-11-15f7873f"  # or your actual project ID
export ZONE="us-east1-a"

# Verify you're authenticated
gcloud auth list
gcloud config set project $PROJECT_ID
```

### Step 1: Enable APIs (Minimal Version)
```bash
# Use the playground-friendly script
./enable-apis-minimal.sh
```

If you get permission errors, try enabling APIs manually in the Console:
- Go to APIs & Services > Library
- Enable: Cloud Build, Container Registry, Kubernetes Engine

### Step 2: Build Your Application
```bash
# Use playground-optimized build script
./cloudbuild-playground.sh

# Submit the build
gcloud builds submit --config=cloudbuild.yaml HelloWorldNodeJs/
```

### Step 3: Deploy Application
```bash
# Use simplified deployment (bypasses Cloud Deploy)
./deploy-playground.sh
```

## Common Permission Issues & Solutions

### Issue: `setIamPolicy` Permission Denied
**Solution:** Use the minimal scripts that avoid IAM operations:
- `enable-apis-minimal.sh` instead of `enable-apis.sh`
- `cloudbuild-playground.sh` instead of `cloudbuild.sh`
- `deploy-playground.sh` instead of `deploy.sh`

### Issue: Artifact Registry Access Denied
**Solution:** The playground scripts use Container Registry (`gcr.io`) instead of Artifact Registry

### Issue: Cloud Deploy Permissions
**Solution:** `deploy-playground.sh` bypasses Cloud Deploy and uses direct Kubernetes deployment

### Issue: Quota Exceeded
**Solution:** The playground scripts use smaller machine types and fewer resources:
- `e2-medium` instead of `n1-standard-4`
- Single-node cluster with autoscaling
- Reduced memory/CPU limits

## Manual Workarounds

### If Scripts Fail Completely
1. **Enable APIs via Console:**
   - Navigation menu → APIs & Services → Library
   - Search and enable: Cloud Build, Kubernetes Engine, Container Registry

2. **Build via Console:**
   - Navigation menu → Cloud Build → History
   - Click "Run build" and upload your source

3. **Deploy via Console:**
   - Navigation menu → Kubernetes Engine → Workloads
   - Click "Deploy" and use the container image from step 2

### Alternative: Use Cloud Shell
Cloud Shell typically has broader permissions than playground accounts:
```bash
# In Cloud Shell, you can often use the full scripts
./enable-apis.sh
./cloudbuild.sh
./clouddeploy.sh
./deploy.sh
```

## Verification Commands

Check if your setup is working:
```bash
# Check enabled APIs
gcloud services list --enabled

# Check container images
gcloud container images list --repository=gcr.io/$PROJECT_ID

# Check clusters
gcloud container clusters list

# Check builds
gcloud builds list --limit=5
```

## Troubleshooting

### Build Fails
```bash
# Check build logs
gcloud builds log <BUILD_ID>

# Check source files
ls -la HelloWorldNodeJs/
```

### Deployment Fails
```bash
# Check cluster status
kubectl get pods
kubectl get services
kubectl describe pod <POD_NAME>
```

### Permission Denied Errors
1. Try using Cloud Shell instead of local terminal
2. Check if you're using the correct project ID
3. Verify your account has at least Viewer + specific service permissions
4. Contact your lab administrator for additional permissions

## Resource Cleanup

When you're done with the playground:
```bash
# Delete cluster to avoid charges
gcloud container clusters delete playground-cluster --zone=us-central1-b

# Delete container images
gcloud container images delete gcr.io/$PROJECT_ID/helloworld:latest
```

## Next Steps

Once you have the playground version working:
1. Try the full pipeline scripts in a project where you have Owner permissions
2. Explore Cloud Deploy features for production environments
3. Add monitoring and logging to your deployments
4. Implement proper CI/CD with source repositories