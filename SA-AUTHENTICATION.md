# Service Account Authentication Guide

This guide shows how to use service account credentials (JSON key files) to isolate permissions for CI/CD builds, providing better security and access control.

## Why Use Service Accounts?

### Benefits
- **🔒 Isolation**: Separate permissions for CI/CD vs user accounts
- **🎯 Principle of Least Privilege**: Grant only required permissions
- **🔄 Rotation**: Easily rotate credentials without affecting users
- **📊 Auditing**: Clear separation of automated vs manual actions
- **🤖 Automation**: Perfect for automated builds and deployments

### Use Cases
- Automated CI/CD pipelines
- Scheduled builds and deployments
- Cross-project deployments
- Restricted playground environments
- Production deployments with controlled permissions

## Quick Start

### Step 1: Create Service Account
```bash
# Set your project
export PROJECT_ID="your-project-id"

# Create service account with minimal permissions
./service-account-setup.sh
```

This creates:
- A new service account: `cicd-pipeline-sa`
- JSON key file: `service-account-key.json`
- Minimal required IAM roles
- Authentication helper script

### Step 2: Use Service Account
```bash
# Method 1: Authenticate directly
./authenticate-service-account.sh

# Method 2: Use in Cloud Build
./cloudbuild-with-sa.sh
gcloud builds submit --config=cloudbuild-sa.yaml .

# Method 3: Environment variable
export GOOGLE_APPLICATION_CREDENTIALS="./service-account-key.json"
```

## Detailed Setup

### Manual Service Account Creation
```bash
# Create service account
gcloud iam service-accounts create cicd-pipeline-sa \
    --display-name="CI/CD Pipeline Service Account" \
    --description="Service account for automated CI/CD operations"

# Assign minimal roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.builder"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Generate key
gcloud iam service-accounts keys create service-account-key.json \
    --iam-account="cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

### Required IAM Roles

#### Minimal Roles (Cloud Build only)
```bash
roles/cloudbuild.builds.builder    # Submit and manage builds
roles/storage.admin                # Access Cloud Storage buckets
roles/container.developer          # Push/pull container images
```

#### Extended Roles (Full CI/CD Pipeline)
```bash
roles/cloudbuild.builds.builder    # Cloud Build operations
roles/storage.admin                # Storage access
roles/container.developer          # Container Registry
roles/containeranalysis.admin      # Container scanning
roles/artifactregistry.writer      # Artifact Registry (alternative to Container Registry)
roles/clouddeploy.releaser         # Cloud Deploy operations
roles/container.clusterAdmin       # GKE cluster management
roles/iam.serviceAccountUser       # Use other service accounts
```

#### Custom Role (Most Restrictive)
```bash
# Create custom role with minimal permissions
gcloud iam roles create cicdPipelineRole \
    --project=$PROJECT_ID \
    --title="CI/CD Pipeline Role" \
    --description="Minimal permissions for CI/CD pipeline" \
    --permissions="cloudbuild.builds.create,cloudbuild.builds.get,storage.objects.create,storage.objects.delete,storage.buckets.get"
```

## Authentication Methods

### Method 1: Environment Variable (Recommended)
```bash
export GOOGLE_APPLICATION_CREDENTIALS="./service-account-key.json"
gcloud auth application-default print-access-token
```

### Method 2: Activate Service Account
```bash
gcloud auth activate-service-account --key-file=service-account-key.json
gcloud config set project $PROJECT_ID
```

### Method 3: Cloud Build Integration
```yaml
steps:
- name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
    gcloud auth activate-service-account --key-file=/workspace/service-account-key.json
    gcloud config set project $PROJECT_ID
```

### Method 4: Docker Container
```bash
# Mount credentials into container
docker run -it \
  -v "$PWD/service-account-key.json:/tmp/key.json" \
  -e GOOGLE_APPLICATION_CREDENTIALS="/tmp/key.json" \
  gcr.io/google.com/cloudsdktool/cloud-sdk:latest \
  gcloud auth list
```

## Security Best Practices

### Key Management
```bash
# 1. Add to .gitignore (automatically done by setup script)
echo "service-account-key.json" >> .gitignore
echo "*.json" >> .gitignore  # Be careful with this one

# 2. Set restrictive file permissions
chmod 600 service-account-key.json

# 3. Regular rotation (every 90 days)
gcloud iam service-accounts keys create new-key.json \
    --iam-account="cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com"

# Delete old key
gcloud iam service-accounts keys delete OLD_KEY_ID \
    --iam-account="cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

### Production Alternatives
```bash
# Option 1: Google Secret Manager
gcloud secrets create cicd-service-account-key --data-file=service-account-key.json

# Option 2: Workload Identity (GKE)
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$PROJECT_ID.svc.id.goog[NAMESPACE/KSA_NAME]" \
    cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com

# Option 3: Cloud Build Service Account
# Use the default Cloud Build service account instead of custom one
```

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Check current authentication
gcloud auth list

# Verify service account has required roles
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

#### Key File Not Found
```bash
# Verify file exists and has correct permissions
ls -la service-account-key.json
file service-account-key.json

# Re-download if corrupted
gcloud iam service-accounts keys create service-account-key.json \
    --iam-account="cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

#### Invalid Key Format
```bash
# Validate JSON format
cat service-account-key.json | jq .

# Check required fields
cat service-account-key.json | jq -r '.type, .project_id, .client_email'
```

### Testing Authentication
```bash
# Test service account authentication
./authenticate-service-account.sh

# Verify permissions
gcloud projects describe $PROJECT_ID
gcloud builds list --limit=1
gcloud container images list --repository=gcr.io/$PROJECT_ID
```

## Integration Examples

### GitHub Actions
```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v1
  with:
    credentials_json: '${{ secrets.GCP_SA_KEY }}'

- name: Set up Cloud SDK
  uses: google-github-actions/setup-gcloud@v1

- name: Build and push
  run: |
    gcloud builds submit --config=cloudbuild-sa.yaml .
```

### GitLab CI
```yaml
variables:
  GOOGLE_APPLICATION_CREDENTIALS: /tmp/gcp-key.json

before_script:
  - echo $GCP_SERVICE_ACCOUNT_KEY | base64 -d > $GOOGLE_APPLICATION_CREDENTIALS
  - gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
```

### Jenkins
```groovy
withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GCP_KEY_FILE')]) {
    sh 'gcloud auth activate-service-account --key-file=$GCP_KEY_FILE'
    sh 'gcloud builds submit --config=cloudbuild-sa.yaml .'
}
```

## Cleanup

### Remove Service Account
```bash
# Delete key file
rm service-account-key.json

# Remove IAM bindings
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.builder"

# Delete service account
gcloud iam service-accounts delete cicd-pipeline-sa@$PROJECT_ID.iam.gserviceaccount.com
```

## Next Steps

1. **Set up monitoring**: Track service account usage with Cloud Audit Logs
2. **Implement rotation**: Set up automated key rotation (90-day cycle)
3. **Use Secret Manager**: Move to Google Secret Manager for production
4. **Workload Identity**: Consider Workload Identity for GKE workloads
5. **Custom roles**: Create more restrictive custom IAM roles as needed