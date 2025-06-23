# GCP CI/CD Pipeline

A complete Google Cloud Platform CI/CD pipeline implementation using Cloud Build, Cloud Deploy, and GKE for automated application deployment across multiple environments.

## Prerequisites

- Google Cloud Platform account with billing enabled
- `gcloud` CLI installed and authenticated
- Docker installed locally (for testing)
- `kubectl` installed for Kubernetes management
- Node.js and npm (for the sample application)

## Environment Setup

1. Set your GCP project ID and preferred zone:
```bash
export PROJECT_ID="your-project-id"
export ZONE="us-east1-a"  # or your preferred zone
```

2. Enable required APIs:
```bash
./enable-apis.sh
```

## Pipeline Architecture

This pipeline implements a complete CI/CD workflow:

1. **Cloud Build** - Builds and pushes Docker images to Artifact Registry
2. **Cloud Deploy** - Manages deployment pipeline with three stages:
   - **Development** - Automatic deployment for testing
   - **Staging** - Automatic deployment for pre-production validation
   - **Production** - Manual approval required for deployment
3. **GKE Clusters** - Kubernetes clusters for each environment
4. **Skaffold** - Declarative deployment configuration

## Quick Start

### Step 1: Create Build Pipeline
Create a build pipeline declaratively via [cloudbuild.yaml](./cloudbuild.yaml) that builds and pushes container images to Artifact Registry:

```bash
./cloudbuild.sh
```

### Step 2: Create Deployment Pipeline
Create a deployment pipeline with three stages (**dev, staging, prod**) using Cloud Deploy:

```bash
./clouddeploy.sh
```
### Step 3: Configure Skaffold
Create [Skaffold](https://skaffold.dev/) configuration for Kubernetes deployment management:

```bash
./skaffold.sh
```

### Step 4: Generate Kubernetes Manifests
Create Kubernetes deployment and service configurations:

```bash
./create-manifest.sh
```

### Step 5: Deploy the Pipeline
Submit the complete pipeline to Cloud Deploy:

```bash
./deploy.sh
```

This executes: `gcloud deploy apply --file clouddeploy.yaml --region=us-central1 --project=$PROJECT_ID`

## Sample Application

The `HelloWorldNodeJs/` directory contains a sample Node.js application that demonstrates the pipeline:

- **Port**: 8080 (internal), exposed as LoadBalancer on port 80
- **Health Check**: Available at `/`
- **Environment**: Supports `TARGET` environment variable for customization
- **Load Testing**: Locust-based load generator included

## Testing

Run the complete test suite:

```bash
./test-runner.sh
```

For detailed testing information, see [README-TESTING.md](./README-TESTING.md).

## Deployment Stages

- **Development**: Automatic deployment on code changes
- **Staging**: Automatic promotion from dev for integration testing
- **Production**: Manual approval required (`requireApproval: true`)

## Troubleshooting

### Common Issues

1. **API not enabled**: Run `./enable-apis.sh` to enable all required services
2. **Permission denied**: Ensure your GCP account has necessary IAM roles:
   - Cloud Build Editor
   - Cloud Deploy Admin
   - Kubernetes Engine Admin
   - Artifact Registry Admin
3. **Cluster not found**: Verify clusters exist in specified zones (us-central1-b)
4. **Image not found**: Check that Cloud Build successfully pushed to `gcr.io/$PROJECT_ID/helloworld`

### Debugging Commands

```bash
# Check Cloud Build status
gcloud builds list --limit=5

# Check Cloud Deploy releases
gcloud deploy releases list --region=us-central1

# Check GKE cluster status
gcloud container clusters list

# View application logs
kubectl logs -l app=helloworld
```

## File Structure

- `*.sh` - Pipeline generation scripts (edit these, not the generated YAML)
- `cloudbuild.yaml` - Generated Cloud Build configuration
- `clouddeploy.yaml` - Generated Cloud Deploy pipeline
- `skaffold.yaml` - Generated Skaffold configuration
- `kubernetes-app.yaml` - Generated Kubernetes manifests
- `HelloWorldNodeJs/` - Sample Node.js application
- `tests/` - BATS test suites for pipeline validation

## Configuration

- **Container Registry**: `gcr.io/$PROJECT_ID/helloworld`
- **Deployment Region**: us-central1
- **Cluster Zones**: us-central1-b
- **Default Zone**: us-east1-a (configurable via `$ZONE`)

## Next Steps

- Customize the sample application in `HelloWorldNodeJs/`
- Modify deployment stages in `clouddeploy.sh`
- Add additional environments or approval processes
- Integrate with your source control system
- Set up monitoring and alerting

