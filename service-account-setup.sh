#!/bin/bash
# Service Account Setup for Isolated CI/CD Permissions
# Creates a dedicated service account with minimal required permissions

set -e

# Configuration
SA_NAME="cicd-pipeline-sa"
SA_DISPLAY_NAME="CI/CD Pipeline Service Account"
SA_DESCRIPTION="Service account for automated CI/CD pipeline operations"
KEY_FILE="./service-account-key.json"

echo "🔧 Setting up isolated service account for CI/CD pipeline"
echo "========================================================="

# Check prerequisites
if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID not set. Please run: export PROJECT_ID=your-project-id"
    exit 1
fi

echo "📋 Project: $PROJECT_ID"
echo "🤖 Service Account: $SA_NAME"
echo ""

# Step 1: Create service account
echo "🆕 Step 1: Creating service account..."
if gcloud iam service-accounts describe "$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" >/dev/null 2>&1; then
    echo "✅ Service account already exists"
else
    gcloud iam service-accounts create $SA_NAME \
        --display-name="$SA_DISPLAY_NAME" \
        --description="$SA_DESCRIPTION" \
        --project=$PROJECT_ID
    echo "✅ Service account created"
fi

# Step 2: Assign minimal required roles
echo ""
echo "🔑 Step 2: Assigning minimal required roles..."

# Core roles for CI/CD pipeline
ROLES=(
    "roles/cloudbuild.builds.builder"
    "roles/storage.admin"
    "roles/container.developer"
    "roles/containeranalysis.admin"
    "roles/artifactregistry.writer"
    "roles/clouddeploy.releaser"
    "roles/container.clusterAdmin"
    "roles/iam.serviceAccountUser"
)

for role in "${ROLES[@]}"; do
    echo "  Adding role: $role"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="$role" \
        --quiet
done

echo "✅ Roles assigned successfully"

# Step 3: Generate and download key
echo ""
echo "🔐 Step 3: Generating service account key..."

# Remove existing key file if it exists
if [ -f "$KEY_FILE" ]; then
    echo "⚠️  Removing existing key file..."
    rm "$KEY_FILE"
fi

# Generate new key
gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --project=$PROJECT_ID

echo "✅ Service account key generated: $KEY_FILE"

# Step 4: Security recommendations
echo ""
echo "🔒 Step 4: Security recommendations..."
echo "✅ Service account created with minimal permissions"
echo "⚠️  IMPORTANT: Secure your key file!"
echo "   - Add $KEY_FILE to .gitignore"
echo "   - Never commit service account keys to version control"
echo "   - Consider using environment variables or secret managers"
echo "   - Rotate keys regularly (recommended: every 90 days)"

# Step 5: Usage instructions
echo ""
echo "🚀 Step 5: Usage instructions..."
echo ""
echo "To use this service account for builds:"
echo ""
echo "# Method 1: Environment variable"
echo "export GOOGLE_APPLICATION_CREDENTIALS=\"$PWD/$KEY_FILE\""
echo ""
echo "# Method 2: gcloud auth activate-service-account"
echo "gcloud auth activate-service-account --key-file=$KEY_FILE"
echo ""
echo "# Method 3: Cloud Build (add to cloudbuild.yaml)"
echo "# - name: 'gcr.io/cloud-builders/gcloud'"
echo "#   entrypoint: 'bash'"
echo "#   args:"
echo "#   - '-c'"
echo "#   - |"
echo "#     gcloud auth activate-service-account --key-file=/workspace/service-account-key.json"
echo ""
echo "# Verify authentication"
echo "gcloud auth list"
echo ""

# Step 6: Add to .gitignore
echo "📝 Step 6: Updating .gitignore..."
if ! grep -q "service-account-key.json" .gitignore 2>/dev/null; then
    echo "service-account-key.json" >> .gitignore
    echo "✅ Added service-account-key.json to .gitignore"
else
    echo "✅ service-account-key.json already in .gitignore"
fi

# Step 7: Create playground-friendly version
echo ""
echo "🎮 Step 7: Creating playground-friendly version..."
cat > ./authenticate-service-account.sh << 'EOF'
#!/bin/bash
# Authenticate using service account key
# Use this script in environments where you have the JSON key file

set -e

KEY_FILE="./service-account-key.json"

if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Service account key file not found: $KEY_FILE"
    echo "Please run ./service-account-setup.sh first"
    exit 1
fi

echo "🔐 Authenticating with service account..."
gcloud auth activate-service-account --key-file=$KEY_FILE

echo "✅ Authentication successful"
echo "Current account: $(gcloud config get-value account)"

# Set project from key file
PROJECT_ID=$(cat $KEY_FILE | grep -o '"project_id": "[^"]*' | cut -d'"' -f4)
gcloud config set project $PROJECT_ID
echo "✅ Project set to: $PROJECT_ID"
EOF

chmod +x ./authenticate-service-account.sh
echo "✅ Created authenticate-service-account.sh"

echo ""
echo "🎉 Service account setup complete!"
echo ""
echo "Next steps:"
echo "1. Review the generated key file (but don't commit it!)"
echo "2. Test authentication: ./authenticate-service-account.sh"
echo "3. Run your CI/CD pipeline with isolated permissions"
echo "4. Consider using Google Secret Manager for production environments"