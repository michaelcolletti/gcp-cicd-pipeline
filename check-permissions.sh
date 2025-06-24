#!/bin/bash
# Permission checker script for GCP playground environments
# Helps diagnose permission issues before running the pipeline

set -e

echo "🔍 GCP Permission Checker for Playground Environments"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if PROJECT_ID is set
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ PROJECT_ID not set${NC}"
    echo "Please set your project ID: export PROJECT_ID=your-project-id"
    exit 1
fi

echo -e "${BLUE}🔧 Checking project: $PROJECT_ID${NC}"
echo ""

# Function to check command success
check_permission() {
    local command="$1"
    local description="$2"
    local required="$3"
    
    printf "%-50s" "$description"
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        if [ "$required" = "required" ]; then
            echo -e "${RED}❌ FAIL (Required)${NC}"
        else
            echo -e "${YELLOW}⚠️  FAIL (Optional)${NC}"
        fi
        return 1
    fi
}

# Check basic authentication
echo -e "${BLUE}🔐 Authentication Status${NC}"
echo "Current account: $(gcloud config get-value account)"
echo "Current project: $(gcloud config get-value project)"
echo ""

# Check project access
echo -e "${BLUE}📋 Project Access${NC}"
check_permission "gcloud projects describe $PROJECT_ID" "Project access" "required"
check_permission "gcloud projects get-iam-policy $PROJECT_ID" "IAM policy read" "optional"
echo ""

# Check API status
echo -e "${BLUE}🔌 API Status${NC}"
check_permission "gcloud services list --enabled --filter='name:container.googleapis.com'" "Kubernetes Engine API" "required"
check_permission "gcloud services list --enabled --filter='name:cloudbuild.googleapis.com'" "Cloud Build API" "required"
check_permission "gcloud services list --enabled --filter='name:artifactregistry.googleapis.com'" "Artifact Registry API" "optional"
check_permission "gcloud services list --enabled --filter='name:clouddeploy.googleapis.com'" "Cloud Deploy API" "optional"
echo ""

# Check service permissions
echo -e "${BLUE}🛠️ Service Permissions${NC}"
check_permission "gcloud builds list --limit=1" "Cloud Build access" "required"
check_permission "gcloud container clusters list" "GKE cluster access" "required"
check_permission "gcloud container images list --repository=gcr.io/$PROJECT_ID" "Container Registry access" "required"
check_permission "gcloud deploy delivery-pipelines list --region=us-central1" "Cloud Deploy access" "optional"
echo ""

# Check compute quotas
echo -e "${BLUE}📊 Compute Quotas${NC}"
check_permission "gcloud compute project-info describe --format='value(quotas)'" "Compute quota access" "required"
echo ""

# Check IAM permissions
echo -e "${BLUE}🔑 IAM Permissions${NC}"
check_permission "gcloud projects add-iam-policy-binding $PROJECT_ID --member='user:$(gcloud config get-value account)' --role='roles/viewer' --dry-run" "IAM policy binding" "optional"
check_permission "gcloud iam service-accounts list" "Service account access" "optional"
echo ""

# Summary and recommendations
echo -e "${BLUE}📝 Summary & Recommendations${NC}"
echo ""

# Check if core requirements are met
CORE_APIS_ENABLED=true
CORE_PERMISSIONS=true

if ! gcloud services list --enabled --filter='name:container.googleapis.com' | grep -q container.googleapis.com; then
    CORE_APIS_ENABLED=false
fi

if ! gcloud services list --enabled --filter='name:cloudbuild.googleapis.com' | grep -q cloudbuild.googleapis.com; then
    CORE_APIS_ENABLED=false
fi

if ! gcloud builds list --limit=1 >/dev/null 2>&1; then
    CORE_PERMISSIONS=false
fi

if ! gcloud container clusters list >/dev/null 2>&1; then
    CORE_PERMISSIONS=false
fi

# Provide recommendations
if [ "$CORE_APIS_ENABLED" = true ] && [ "$CORE_PERMISSIONS" = true ]; then
    echo -e "${GREEN}✅ Core requirements met!${NC}"
    echo "Recommended approach:"
    echo "  1. Use ./cloudbuild-playground.sh for building"
    echo "  2. Use ./deploy-playground.sh for deployment"
    echo "  3. Run the full pipeline with playground scripts"
elif [ "$CORE_APIS_ENABLED" = true ]; then
    echo -e "${YELLOW}⚠️  APIs enabled but limited permissions${NC}"
    echo "Recommended approach:"
    echo "  1. Try ./enable-apis-minimal.sh first"
    echo "  2. Use playground-optimized scripts"
    echo "  3. Consider using Cloud Shell for broader permissions"
elif [ "$CORE_PERMISSIONS" = true ]; then
    echo -e "${YELLOW}⚠️  Permissions available but APIs not enabled${NC}"
    echo "Recommended approach:"
    echo "  1. Run ./enable-apis-minimal.sh"
    echo "  2. If that fails, enable APIs manually in Console"
    echo "  3. Then use playground scripts"
else
    echo -e "${RED}❌ Restricted environment detected${NC}"
    echo "Recommended approach:"
    echo "  1. Switch to Cloud Shell if available"
    echo "  2. Enable APIs manually via Console"
    echo "  3. Use manual deployment steps from PLAYGROUND-SETUP.md"
    echo "  4. Contact administrator for additional permissions"
fi

echo ""
echo -e "${BLUE}🔗 Useful Commands${NC}"
echo "Check API status: gcloud services list --enabled"
echo "Check builds: gcloud builds list --limit=5"
echo "Check clusters: gcloud container clusters list"
echo "Check images: gcloud container images list --repository=gcr.io/$PROJECT_ID"
echo ""
echo "For detailed setup instructions, see: PLAYGROUND-SETUP.md"