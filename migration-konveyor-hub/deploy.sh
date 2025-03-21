#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
for cmd in kubectl az jq; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo -e "${RED}Error: $cmd is not installed${NC}"
        exit 1
    fi
done

# Check Azure connection
echo -e "${YELLOW}Checking Azure connection...${NC}"
if ! az account show >/dev/null 2>&1; then
    echo -e "${RED}Error: Not connected to Azure. Please run 'az login' first${NC}"
    exit 1
fi

# Deploy infrastructure first
echo -e "${YELLOW}Deploying infrastructure...${NC}"
cd terraform
terraform init
terraform apply -auto-approve

# Get cluster credentials
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw cluster_name)
cd ..

echo -e "${YELLOW}Getting AKS credentials...${NC}"
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Clean up existing resources (only if cluster exists and accessible)
echo -e "${YELLOW}Cleaning up existing resources...${NC}"
if kubectl cluster-info >/dev/null 2>&1; then
    kubectl delete namespace konveyor-tackle --ignore-not-found
    kubectl delete crd tackles.tackle.konveyor.io addons.tackle.konveyor.io tasks.tackle.konveyor.io extensions.tackle.konveyor.io --ignore-not-found
    kubectl delete clusterrole,clusterrolebinding -l olm.owner=tackle-operator --ignore-not-found
fi

# Install Konveyor
echo -e "${YELLOW}Installing Konveyor...${NC}"
kubectl create namespace konveyor-tackle --dry-run=client -o yaml | kubectl apply -f -

# Install OLM if needed
if ! kubectl get crd subscriptions.operators.coreos.com >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing Operator Lifecycle Manager...${NC}"
    kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/crds.yaml
    kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/olm.yaml
    kubectl wait --for=condition=ready pod -l app=olm-operator -n olm --timeout=300s
fi

# Install Konveyor operator
echo -e "${YELLOW}Installing Konveyor operator...${NC}"
kubectl apply -f https://raw.githubusercontent.com/konveyor/tackle2-operator/main/tackle-k8s.yaml

# Wait for operator to be ready
echo -e "${YELLOW}Waiting for operator to be ready...${NC}"
sleep 30  # Initial wait for resources to be created
kubectl wait --for=condition=ready pod -l name=tackle-operator -n konveyor-tackle --timeout=300s

# Create Tackle CR
echo -e "${YELLOW}Creating Tackle instance...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: tackle.konveyor.io/v1alpha1
kind: Tackle
metadata:
  name: tackle
  namespace: konveyor-tackle
spec:
  feature_auth_required: false
EOF

# Apply custom rules
echo -e "${YELLOW}Applying custom rules...${NC}"
kubectl apply -f tackle-rules-configmap.yaml
kubectl apply -f tackle-custom-rules.yaml

# Apply sample data
echo -e "${YELLOW}Applying sample data...${NC}"
kubectl apply -f tackle-sample-data.yaml

# Wait for deployment
echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
echo -e "${YELLOW}Waiting for resources to be created...${NC}"
sleep 60  # Wait for deployments to be created
kubectl wait --for=condition=available deployment/tackle-hub deployment/tackle-ui -n konveyor-tackle --timeout=300s

# Set up access
echo -e "${YELLOW}Setting up access...${NC}"
# Kill any existing port-forwards on 8181
lsof -ti:8181 | xargs kill -9 2>/dev/null || true
kubectl port-forward svc/tackle-ui 8181:8080 -n konveyor-tackle &
sleep 5

echo -e "${GREEN}Konveyor Hub is ready!${NC}"
echo -e "${YELLOW}Access the UI at: http://localhost:8181${NC}"

# Open browser
open http://localhost:8181 