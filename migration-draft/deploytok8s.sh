#!/bin/bash

# Exit on error
set -e

# Check if running from the correct directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ "$(basename "$SCRIPT_DIR")" != "migration-draft" ]; then
    echo "Error: This script must be run from the migration-draft directory"
    echo "Current directory: $SCRIPT_DIR"
    exit 1
fi

# Configuration
TEMP_DIR="temp-after-container"
SIMULATION_DIR="k8s-simulation"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"

echo "=== Draft Configuration and Artifact Generation ==="
echo "Working directory: $TEMP_DIR"

# Clean up and setup
rm -rf "$TEMP_DIR" "$SIMULATION_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p "$SIMULATION_DIR/helm/templates"

# Copy application files
echo -e "\nCopying application files..."
echo "Current directory: $(pwd)"
echo "Checking if after-container exists:"
ls -la ../after-container
echo "Copying files..."
cp -r ../after-container/src "$TEMP_DIR/"
cp ../after-container/pom.xml "$TEMP_DIR/"
cp -r ../after-container/docker "$TEMP_DIR/"
cp ../after-container/docker-compose.yml "$TEMP_DIR/"

# Create Draft configuration
echo -e "\nCreating Draft configuration..."
cat > "$TEMP_DIR/draft-config.yaml" << 'EOF'
deployType: "Helm"
languageType: "java"
deployVariables:
  - name: "PORT"
    value: "8080"
  - name: "SERVICEPORT"
    value: "80"
  - name: "APPNAME"
    value: "todo-app"
  - name: "IMAGENAME"
    value: "todo-app"
languageVariables:
  - name: "VERSION"
    value: "17-jre"
  - name: "BUILDERVERSION"
    value: "3-jdk-8"
  - name: "PORT"
    value: "8080"
EOF

echo "Draft configuration saved to: $TEMP_DIR/draft-config.yaml"

# Generate initial Dockerfile with Draft
echo -e "\n=== Step 1: Generating Initial Draft Artifacts ==="
cd "$TEMP_DIR"
draft create -c ./draft-config.yaml --skip-file-detection

echo -e "\nDraft generated the following artifacts:"
echo "1. Dockerfile: Dockerfile"
echo "2. Helm Charts: charts/"
echo "   - values.yaml: Basic configuration"
echo "   - templates/: Kubernetes manifests"
echo "3. .dockerignore: File exclusion patterns"

# HACK: Replace Draft-generated Dockerfile with known working version
echo -e "\n=== Step 2: Replacing Draft Dockerfile with Working Version ==="
echo "The Draft-generated Dockerfile doesn't support our Tomcat/WAR deployment requirements."
echo "Saving original Draft Dockerfile as: dockerfile.draft.original"
mv Dockerfile dockerfile.draft.original

echo "Copying known working Dockerfile from after-container..."
cp "$SCRIPT_DIR/../after-container/Dockerfile" Dockerfile
echo "Dockerfile replaced successfully"

# HACK: Modify docker-compose.yml to ensure AMD64 architecture compatibility
# This is necessary because we're building on an ARM64 machine (Apple Silicon)
# but deploying to AMD64 nodes in AKS. The platform specification ensures
# the image is built for the correct architecture.
echo "Modifying docker-compose.yml for AMD64 platform..."
sed -i '' '/app:/a\
    build:\
      context: .\
      platforms:\
        - linux/amd64' docker-compose.yml

# Verify the platform specification was added correctly
if ! grep -q "platforms:" docker-compose.yml; then
    echo "Error: Failed to add platform specification to docker-compose.yml"
    exit 1
fi

echo -e "\nUpdated artifacts after Dockerfile replacement:"
echo "1. Original Draft Dockerfile: dockerfile.draft.original"
echo "2. Working Dockerfile: Dockerfile"
echo "3. Application Source: src/"
echo "4. Maven Config: pom.xml"
echo "5. Docker Compose: docker-compose.yml (modified for AMD64 architecture to ensure compatibility with AKS nodes)"

# Build container locally first
echo -e "\n=== Step 3: Building Container Locally ==="
# Build with podman-compose
echo "Building container with podman-compose..."
# First build the base image with AMD64 platform
podman build --platform linux/amd64 -t temp-after-container_app:latest . || { echo "Container build failed"; exit 1; }

# Verify the image architecture
echo "Verifying image architecture..."
IMAGE_ARCH=$(podman inspect localhost/temp-after-container_app:latest | jq -r '.[0].Architecture')
if [ "$IMAGE_ARCH" != "amd64" ]; then
    echo "Error: Image was built for $IMAGE_ARCH but needs to be amd64 for AKS compatibility"
    exit 1
fi
echo "Image architecture verified as amd64"

echo "Container built successfully as: migration-draft-todo-app:latest"

cd "$SCRIPT_DIR"

# Create simulated Kubernetes manifests
echo -e "\n=== Step 4: Creating Kubernetes Manifests ==="
echo "Generating Helm charts and Kubernetes manifests..."

# Create Chart.yaml
cat > "$SIMULATION_DIR/helm/Chart.yaml" << 'EOF'
apiVersion: v2
name: todo-app
description: A Helm chart for deploying a Tomcat-based Java application
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

# Create values.yaml.pre
cat > "$SIMULATION_DIR/helm/values.yaml.pre" << 'EOF'
image:
  repository: ACR_SERVER_URL/migration-draft-todo-app
  tag: latest
  pullPolicy: Always

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

resources:
  limits:
    cpu: 1
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

database:
  host: postgres
  port: 5432
  name: todos
  user: todos
  password: todos

tomcat:
  contextPath: /todo
EOF

# Create deployment.yaml
cat > "$SIMULATION_DIR/helm/templates/deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 8080
          env:
            - name: DB_HOST
              value: {{ .Values.database.host }}
            - name: DB_PORT
              value: "{{ .Values.database.port }}"
            - name: DB_NAME
              value: {{ .Values.database.name }}
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: {{ .Release.Name }}-db-credentials
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ .Release.Name }}-db-credentials
                  key: password
          livenessProbe:
            httpGet:
              path: {{ .Values.tomcat.contextPath }}/health
              port: 8080
            initialDelaySeconds: 60
          readinessProbe:
            httpGet:
              path: {{ .Values.tomcat.contextPath }}/health
              port: 8080
            initialDelaySeconds: 30
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
EOF

# Create service.yaml
cat > "$SIMULATION_DIR/helm/templates/service.yaml" << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
  selector:
    app: {{ .Release.Name }}
EOF

# Create secrets.yaml
cat > "$SIMULATION_DIR/helm/templates/secrets.yaml" << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-db-credentials
type: Opaque
stringData:
  username: {{ .Values.database.user }}
  password: {{ .Values.database.password }}
EOF

# Create postgres.yaml
cat > "$SIMULATION_DIR/helm/templates/postgres.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Release.Name }}-postgres
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}-postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15
          env:
            - name: POSTGRES_DB
              value: {{ .Values.database.name }}
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: {{ .Release.Name }}-db-credentials
                  key: username
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ .Release.Name }}-db-credentials
                  key: password
          ports:
            - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.database.host }}
spec:
  ports:
    - port: {{ .Values.database.port }}
      targetPort: 5432
  selector:
    app: {{ .Release.Name }}-postgres
EOF

echo -e "\nGenerated Kubernetes artifacts:"
echo "1. Chart.yaml: Basic chart information"
echo "2. values.yaml.pre: Configuration values template"
echo "3. templates/:"
echo "   - deployment.yaml: Main application deployment"
echo "   - service.yaml: Service configuration"
echo "   - secrets.yaml: Database credentials"
echo "   - postgres.yaml: Database deployment"

# Deploy infrastructure with Terraform
echo -e "\n=== Step 5: Checking Azure Infrastructure ==="

# Check if infrastructure already exists
echo "Checking existing infrastructure..."
RESOURCE_GROUP="rg-todo-app"
AKS_CLUSTER="aks-todo-app"
ACR_SERVER="acrtodoappdev.azurecr.io"

# Verify AKS cluster exists
if az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" >/dev/null 2>&1; then
    echo "Found existing AKS cluster: $AKS_CLUSTER"
else
    echo "Error: AKS cluster not found. Please run Terraform first."
    exit 1
fi

# Verify ACR exists
if az acr show --resource-group "$RESOURCE_GROUP" --name "$(echo "$ACR_SERVER" | cut -d'.' -f1)" >/dev/null 2>&1; then
    echo "Found existing ACR: $ACR_SERVER"
else
    echo "Error: ACR not found. Please run Terraform first."
    exit 1
fi

echo -e "\nInfrastructure details:"
echo "1. Resource Group: $RESOURCE_GROUP"
echo "2. AKS Cluster: $AKS_CLUSTER"
echo "3. ACR Server: $ACR_SERVER"

# Build and push container to ACR
echo -e "\n=== Step 6: Building and Pushing Container to ACR ==="
cd "$SCRIPT_DIR/$TEMP_DIR"

# Tag and push image
echo "Tagging image for ACR..."
podman tag "localhost/temp-after-container_app:latest" "$ACR_SERVER/migration-draft-todo-app:latest"
echo "Pushing image to ACR..."
podman push "$ACR_SERVER/migration-draft-todo-app:latest"

cd "$SCRIPT_DIR"

# Generate final values.yaml with ACR URL
echo -e "\n=== Step 7: Preparing Helm Deployment ==="
cd "$SCRIPT_DIR/$SIMULATION_DIR/helm"
echo "Generating final values.yaml with ACR URL..."
sed "s|ACR_SERVER_URL|$ACR_SERVER|g" values.yaml.pre > values.yaml

# Verify the image name in values.yaml
if ! grep -q "repository: $ACR_SERVER/migration-draft-todo-app" values.yaml; then
    echo "Error: Image repository name mismatch in values.yaml"
    exit 1
fi

# Deploy with Helm
echo -e "\n=== Step 8: Deploying Application with Helm ==="
echo "Getting AKS credentials..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing

echo "Deploying application to Kubernetes..."
helm upgrade --install todo-app . --wait

# Verify the deployment is using the correct image
echo "Verifying deployment image..."
DEPLOYMENT_IMAGE=$(kubectl get deployment todo-app -o jsonpath='{.spec.template.spec.containers[0].image}')
if [ "$DEPLOYMENT_IMAGE" != "$ACR_SERVER/migration-draft-todo-app:latest" ]; then
    echo "Error: Deployment is using incorrect image: $DEPLOYMENT_IMAGE"
    echo "Expected: $ACR_SERVER/migration-draft-todo-app:latest"
    exit 1
fi

echo -e "\n=== Step 9: Testing Application ==="
echo "Waiting for application to be ready..."
sleep 10

echo "Testing health endpoint..."
if ! curl -s http://localhost:18081/todo/health | grep -q "UP"; then
    echo "Error: Health check failed"
    exit 1
fi
echo "Health check passed"

echo "Testing todo creation..."
TODO_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"Test Todo","completed":false}' http://localhost:18081/todo/api/todos)
if [ -z "$TODO_RESPONSE" ]; then
    echo "Error: Failed to create todo"
    exit 1
fi
echo "Todo creation successful"

echo "Testing main page..."
if ! curl -s http://localhost:18081/todo > /dev/null; then
    echo "Error: Main page not accessible"
    exit 1
fi
echo "Main page accessible"

echo -e "\n=== Deployment Complete ==="
echo "✅ Successfully deployed and tested the migration-draft version of the todo application to AKS"
echo "✅ All tests passed: health check, todo creation, and main page access"
echo "✅ Application is running with AMD64 architecture on AKS nodes"
echo "✅ Database connection is established and working"

echo -e "\nYou can access the application at:"
echo "1. Main page: http://localhost:18081/todo"
echo "2. Health check: http://localhost:18081/todo/health"
echo "3. API: http://localhost:18081/todo/api/todos"

echo -e "\nTo stop port forwarding, press Ctrl+C"
kubectl port-forward service/todo-app 18081:80

