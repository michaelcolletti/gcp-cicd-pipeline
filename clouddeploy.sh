cat <<EOF > clouddeploy.yaml
apiVersion: deploy.cloud.google.com/v1beta1
kind: DeliveryPipeline
metadata:
  name: helloworld-pipeline
  description: helloworld application delivery pipeline
serialPipeline:
  stages:
  - targetId: dev
    profiles: []
  - targetId: staging
    profiles: []
  - targetId: prod
    profiles: []
---
apiVersion: deploy.cloud.google.com/v1beta1
kind: Target
metadata:
  name: dev
  description: dev cluster
gke:
  cluster: projects/\$PROJECT_ID/locations/us-central1-b/clusters/dev-cluster
---
apiVersion: deploy.cloud.google.com/v1beta1
kind: Target
metadata:
  name: staging
  description: staging cluster
gke:
  cluster: projects/\$PROJECT_ID/locations/us-central1-b/clusters/staging-cluster
---
apiVersion: deploy.cloud.google.com/v1beta1
kind: Target
metadata:
  name: prod
  description: prod cluster
  requireApproval: true
gke:
  cluster: projects/\$PROJECT_ID/locations/us-central1-b/clusters/prod-cluster
EOF
