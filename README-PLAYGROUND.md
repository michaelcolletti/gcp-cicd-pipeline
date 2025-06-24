# GCP CI/CD Pipeline - Playground Edition

A streamlined version of the GCP CI/CD pipeline designed specifically for **Google Cloud Playground environments** and **restricted lab accounts** with limited IAM permissions.

## 🎯 Quick Start (5 minutes)

### Prerequisites
- Active Google Cloud Playground session
- Cloud Shell access (recommended) or local `gcloud` CLI
- Basic familiarity with terminal commands

### Setup Commands
```bash
# 1. Set your project (use your actual playground project ID)
export PROJECT_ID="playground-s-11-abc123def"
export ZONE="us-east1-a"

# 2. Check your permissions first
./check-permissions.sh

# 3. Enable required APIs (playground-friendly)
./enable-apis-minimal.sh

# 4. Build your application
./cloudbuild-playground.sh
gcloud builds submit --config=cloudbuild.yaml HelloWorldNodeJs/

# 5. Deploy to Kubernetes
./deploy-playground.sh
```

**Expected completion time:** 5-10 minutes
**Cost:** Usually free within playground credits

## 🔍 What's Different from Production?

| Feature | Production Version | Playground Version |
|---------|-------------------|-------------------|
| **Container Registry** | Artifact Registry | Container Registry (gcr.io) |
| **Deployment** | Cloud Deploy pipeline | Direct Kubernetes deployment |
| **IAM Setup** | Full service account setup | Skips IAM operations |
| **Clusters** | 3 environments (dev/staging/prod) | Single playground cluster |
| **Approval Gates** | Manual approval for prod | Automatic deployment |
| **Machine Types** | Standard/optimized | Smaller, quota-friendly |

## 📋 Playground-Specific Scripts

### Core Scripts
- **`check-permissions.sh`** - Diagnose what permissions you have
- **`enable-apis-minimal.sh`** - Enable APIs without IAM operations
- **`cloudbuild-playground.sh`** - Generate playground-friendly build config
- **`deploy-playground.sh`** - Deploy directly to Kubernetes (bypasses Cloud Deploy)

### Helper Files
- **`PLAYGROUND-SETUP.md`** - Detailed troubleshooting guide
- **`cloudbuild.yaml`** - Generated build configuration (playground version)

## 🚨 Common Issues & Quick Fixes

### ❌ "Permission denied" on IAM operations
```bash
# Use minimal scripts instead
./enable-apis-minimal.sh        # instead of ./enable-apis.sh
./cloudbuild-playground.sh      # instead of ./cloudbuild.sh
./deploy-playground.sh          # instead of ./deploy.sh
```

### ❌ "Quota exceeded" errors
```bash
# The playground scripts use smaller resources automatically
# If you still hit quotas, try a different region:
export ZONE="us-west1-a"
./deploy-playground.sh
```

### ❌ "Cloud Deploy not available"
```bash
# Playground version skips Cloud Deploy entirely
# Uses direct Kubernetes deployment instead
./deploy-playground.sh
```

### ❌ "Artifact Registry permission denied"
```bash
# Playground version uses Container Registry (gcr.io)
# This is automatically configured in playground scripts
```

## 🧪 Testing Your Deployment

Once deployed, test your application:
```bash
# Get the external IP
kubectl get service helloworld-service

# Test the endpoint (replace with your actual IP)
curl http://YOUR-EXTERNAL-IP

# Expected response: "Hello Playground Environment!"
```

## 📊 Monitoring Your Resources

```bash
# Check pod status
kubectl get pods -l app=helloworld

# Check service status
kubectl get service helloworld-service

# View application logs
kubectl logs -l app=helloworld

# Check build history
gcloud builds list --limit=5
```

## 🧹 Cleanup (Important!)

**Always clean up playground resources to avoid charges:**
```bash
# Delete Kubernetes resources
kubectl delete service helloworld-service
kubectl delete deployment helloworld

# Delete cluster
gcloud container clusters delete playground-cluster --zone=us-central1-b

# Delete container images
gcloud container images delete gcr.io/$PROJECT_ID/helloworld:latest
```

## 🔄 Troubleshooting Workflow

1. **Start with permission check:**
   ```bash
   ./check-permissions.sh
   ```

2. **If APIs aren't enabled:**
   ```bash
   # Try minimal script first
   ./enable-apis-minimal.sh
   
   # If that fails, enable manually in Console:
   # Navigation menu → APIs & Services → Library
   ```

3. **If build fails:**
   ```bash
   # Check build logs
   gcloud builds list --limit=1
   gcloud builds log <BUILD_ID>
   ```

4. **If deployment fails:**
   ```bash
   # Check cluster and pods
   kubectl get pods
   kubectl describe pod <POD_NAME>
   ```

5. **Still having issues?**
   - Try using **Cloud Shell** instead of local terminal
   - Check **PLAYGROUND-SETUP.md** for detailed troubleshooting
   - Use manual deployment steps in the setup guide

## 💡 Pro Tips for Playgrounds

1. **Use Cloud Shell:** Generally has broader permissions than lab accounts
2. **Work in one session:** Avoid starting/stopping - complete the whole pipeline in one go
3. **Monitor quotas:** Playground environments have limited quotas
4. **Check time limits:** Most playgrounds have session time limits
5. **Document your work:** Take screenshots for later reference

## 🚀 Next Steps

Once you have the playground version working:

1. **Explore the application:** Modify `HelloWorldNodeJs/index.js` and redeploy
2. **Scale your deployment:** Try `kubectl scale deployment helloworld --replicas=3`
3. **Add monitoring:** Check out the logs and metrics in the GCP Console
4. **Learn more:** Review the full production pipeline in the main README.md

## 📚 Additional Resources

- **Main README.md** - Full production pipeline documentation
- **PLAYGROUND-SETUP.md** - Detailed troubleshooting and manual steps
- **demo-script.md** - Step-by-step demo walkthrough
- **HelloWorldNodeJs/** - Sample application source code

## 🆘 Getting Help

If you're still having issues:
1. Run `./check-permissions.sh` and share the output
2. Check build logs: `gcloud builds list --limit=5`
3. Verify your project ID: `echo $PROJECT_ID`
4. Try the manual deployment steps in **PLAYGROUND-SETUP.md**

---

**Happy building! 🎉**

*This playground version is designed to get you up and running quickly in restricted environments. For production deployments, see the main README.md for the full CI/CD pipeline with proper staging, approvals, and monitoring.*