# Deployment to AKS with Draft

This directory contains a copy of the todo application that was previously modernized using Konveyor Kantra. We're now using this modernized version to demonstrate how to deploy a Tomcat-based Java application to Kubernetes using [Draft](https://github.com/Azure/draft), a tool that helps developers create containerized applications and deploy them to Kubernetes.

## Quick Start

```bash
./deploytok8s.sh
```

After deployment, access the application at:
- Main application: http://localhost:18081/todo
- Health check: http://localhost:18081/todo/health
- API: http://localhost:18081/todo/api/todos

## About This Project

This project demonstrates deploying the modernized Todo application (from [after-container](../after-container)) to Kubernetes using Draft. While Draft provides good support for modern frameworks, we encountered limitations with its Java template for our Tomcat-based application. We've used AI assistance to enhance the generated artifacts with proper Tomcat configuration.

### Draft and AI Integration

Draft's Java template works well for Spring Boot apps but didn't fully support our Tomcat-based application. We used Draft to generate initial artifacts and then enhanced them with AI assistance:

```bash
# Our Draft configuration
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

# Draft command used
draft create -c ./draft-config.yaml --skip-file-detection
```

### Relation to Konveyor

The [Konveyor AI (KAI)](https://github.com/konveyor/kai) project offers insights into AI-assisted application modernization. While KAI currently focuses on suggesting code modifications based on static analysis, our approach uses AI to enhance deployment artifacts. Combining KAI's code modernization approach with Draft's artifact generation could create a more complete modernization-to-deployment pipeline.

## Application Overview

### Technical Details
- **Runtime**: Java 17, Tomcat 9
- **Database**: PostgreSQL
- **Build**: Maven

### Configuration
The application uses these environment variables:
- `DB_HOST`: Database host name
- `DB_PORT`: Database port (default: 5432)
- `DB_NAME`: Database name
- `DB_USER`: Database user
- `DB_PASSWORD`: Database password

### Monitoring
- Health check endpoint at `/todo/health`
- Returns `{"status":"UP"}` when healthy
- Returns HTTP 503 when unhealthy

## Deployment Process

### Prerequisites
- Draft CLI installed
- Terraform CLI installed
- Azure CLI configured with appropriate permissions
- Container registry access (ACR)
- Podman configured for Azure authentication

### Deployment Steps

The `deploytok8s.sh` script automates the entire deployment process:

1. **Artifact Generation and Enhancement**
   - Creates working directory and copies source files
   - Generates basic artifacts with Draft
   - Enhances artifacts with AI-generated improvements

2. **Container Build and Registry Operations**
   - Builds with Maven
   - Creates container image with enhanced Dockerfile
   - Pushes to Azure Container Registry

3. **Infrastructure Management**
   - Provisions AKS cluster and ACR with Terraform
   - Configures IAM permissions
   - Sets up Kubernetes context

4. **Application Deployment**
   - Deploys using Helm
   - Configures services and environment
   - Enables access through port forwarding

### Cleanup
```bash
helm uninstall todo-app
kubectl delete pod --all --force
```

## Implementation Details

### Enhanced Artifacts

The AI-enhanced deployment artifacts include:
- **Multi-stage Dockerfile** with Tomcat support
- **Comprehensive Helm charts** with database integration
- **Enhanced Kubernetes manifests** with proper configurations
- **Database Support**: PostgreSQL deployment
- **Environment Configuration**: Proper secrets management
- **Resource Management**: Configurable limits and requests

### Generated Kubernetes Resources

```
k8s-simulation/helm/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Configuration values
└── templates/     
    ├── deployment.yaml     # Tomcat application
    ├── service.yaml        # Service configuration
    ├── configmap.yaml      # Environment variables
    └── postgres.yaml       # Required database
```

### Project Structure

```
migration-draft/
├── deploytok8s.sh          # Main deployment script
├── k8s-simulation/         # AI-generated Kubernetes manifests
└── temp-after-container/   # Working directory (created during deployment)
    ├── src/                # Application source
    ├── pom.xml             # Build configuration
    ├── dockerfile          # AI-enhanced Dockerfile
    └── charts/             # Generated Helm charts
```