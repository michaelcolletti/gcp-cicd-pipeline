cat <<EOF > cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'gcr.io/$PROJECT_ID/helloworld', '.']
# Push the container image to Artifact Registry
- name: 'gcr.io/cloud-builders/docker'
  args: ['push', 'gcr.io/$PROJECT_ID/helloworld']
# Create release in Google Cloud Deploy
- name: gcr.io/google.com/cloudsdktool/cloud-sdk
  entrypoint: gcloud
  args: ["beta", "deploy", "releases", "create", "rel-\${SHORT_SHA}a",
"--delivery-pipeline", "helloworld-pipeline",
"--region", "us-central1",
"--annotations", "commitId=\${REVISION_ID}",
"--images", "helloworld=gcr.io/$PROJECT_ID/helloworld"]
EOF

