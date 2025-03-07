# Deployment to AKS with Draft

This directory contains a copy of the todo application that was previously modernized using Konveyor Kantra. We're now using this modernized version to demonstrate how to deploy a Tomcat-based Java application to Kubernetes using [Draft](https://github.com/Azure/draft), a tool that helps developers create containerized applications and deploy them to Kubernetes.

## About Draft and This Project

[Draft](https://github.com/Azure/draft) is an open-source tool that helps developers create containerized applications and deploy them to Kubernetes. It provides templates and automation to generate Dockerfiles, Kubernetes manifests, and Helm charts based on the application's language and framework. While Draft provides good support for modern frameworks, its current templates are primarily focused on modern applications and appeared to not fully support legacy Java/Tomcat applications such as our todo app. This project explores how we can bridge this gap using AI to generate the necessary artifacts with the modernized version of the todo application contained in the [after-container](../after-container) project directory.

## Important Disclaimer and AI Integration

For the purposes of this demo, we encountered limitations with Draft's Java template that we were unable to overcome. We initially attempted to use Draft with the following command and configuration:

```bash
# Contents of draft-config.yaml
deployType: "Helm"          # Type of deployment artifacts to generate
languageType: "java"        # Programming language/platform
deployVariables:            # Variables for deployment configuration
  - name: "PORT"           # Container port
    value: "8080"
  - name: "SERVICEPORT"    # Service port
    value: "80"
  - name: "APPNAME"        # Application name
    value: "todo-app"
  - name: "IMAGENAME"      # Container image name
    value: "todo-app"
languageVariables:          # Language-specific variables
  - name: "VERSION"        # Java runtime version
    value: "17-jre"
  - name: "BUILDERVERSION" # Build environment version
    value: "3-jdk-8"
  - name: "PORT"          # Application port
    value: "8080"

# Draft command
draft create -c ./draft-config.yaml --skip-file-detection
```

This command used Draft's Java template, which works well for Spring Boot apps but didn't fully support our Tomcat-based application. Rather than starting from scratch, we used AI (Claude 3.5 Sonnet) to enhance Draft's generated artifacts, adding the necessary Tomcat configuration, database support, and health checks.

The [Konveyor AI (KAI)](https://github.com/konveyor/kai) project offers interesting insights into how AI can assist with application modernization. While our approach with Draft used AI to enhance deployment artifacts, KAI currently focuses on using AI to suggest code modifications based on static analysis rule violations - something we had already addressed in our modernized [after-container](../after-container) version (ironically, also with AI assistance). What Konveyor currently lacks is artifact generation capabilities for deploying these modernized applications. This presents an opportunity: by using the approach from KAI's AI-assisted approach and combining it with Draft, we could create a more end-to-end modernization solution. Draft could generate the initial deployment artifacts, and then AI could enhance them based on analysis of the codebase and existing configuration files (like our docker-compose.yml). This would bridge the gap between application modernization (KAI's current focus) and deployment artifact generation (Draft's strength), creating a more complete modernization-to-deployment pipeline.

## Application Overview

### Application Structure
The application is a simple todo list web application built with:
- Java 17
- Apache Tomcat 9
- PostgreSQL database
- Maven for building

### Environment Variables
The application expects the following environment variables:
- `DB_HOST`: Database host name
- `DB_PORT`: Database port (default: 5432)
- `DB_NAME`: Database name
- `DB_USER`: Database user
- `DB_PASSWORD`: Database password

### Health Checks
The application provides a health check endpoint at `/todo/health` that returns:
- `{"status":"UP"}` when healthy
- HTTP 503 when unhealthy

### Database Configuration
The application uses PostgreSQL with the following configuration:
- Database name: todo
- User: todo
- Password: todo123
- Port: 5432

## Deployment Process

### Prerequisites
- Draft CLI installed
- Terraform CLI installed (for AKS cluster provisioning)
- Azure CLI configured with appropriate permissions
- Container registry access (ACR)
- Podman configured for Azure authentication

The `deploytok8s.sh` script uses Terraform to provision a test AKS cluster and ACR in Azure. The Terraform configuration can be found in the `terraform/` directory and handles:
- Resource group creation
- AKS cluster deployment with appropriate node pools
- ACR creation and configuration
- Required IAM roles and permissions
- System-assigned managed identity for AKS to pull from ACR

### Building and Deploying
To build and deploy the application, run:
```bash
./deploytok8s.sh
```

The script automates the entire deployment process through the following steps:

1. **Draft Configuration and Artifact Generation**
   - Creates working directory and copies source files
   - Generates Draft configuration
   - Creates initial artifacts using Draft
   - Enhances artifacts with AI-generated improvements for Tomcat support

2. **Container Build and Registry Operations**
   - Builds the application using Maven
   - Builds container with AI-enhanced Dockerfile using podman
   - Tags image for ACR using the registry's FQDN
   - Authenticates with ACR using Azure CLI credentials
   - Pushes to ACR
   - Configures AKS to pull from ACR using system-assigned managed identity

3. **Infrastructure Setup**
   - Uses Terraform to provision and manage Azure infrastructure
   - Creates resource group and AKS cluster if they don't exist
   - Deploys ACR with required networking and IAM configuration
   - Sets up AKS system-assigned managed identity with ACR pull permissions
   - Validates infrastructure deployment
   - Configures Kubernetes context for deployment

4. **Application Deployment and Access**
   - Deploys using Helm
   - Sets up services and configurations
   - Verifies deployment status
   - Enables access through port forwarding:
     ```bash
     kubectl port-forward service/todo-app 18081:80
     ```
   - Available endpoints:
     - Main application: http://localhost:18081/todo
     - Health check: http://localhost:18081/todo/health
     - API: http://localhost:18081/todo/api/todos

### Cleanup
To remove the deployment:
```bash
helm uninstall todo-app
kubectl delete pod --all --force
```

## Draft Implementation Details

### Configuration
```yaml
deployType: "Helm"          # Type of deployment artifacts to generate
languageType: "java"        # Programming language/platform
deployVariables:            # Variables for deployment configuration
  - name: "PORT"           # Container port
    value: "8080"
  - name: "SERVICEPORT"    # Service port
    value: "80"
  - name: "APPNAME"        # Application name
    value: "todo-app"
  - name: "IMAGENAME"      # Container image name
    value: "todo-app"
languageVariables:          # Language-specific variables
  - name: "VERSION"        # Java runtime version
    value: "17-jre"
  - name: "BUILDERVERSION" # Build environment version
    value: "3-jdk-8"
  - name: "PORT"          # Application port
    value: "8080"
```

### Generated and Enhanced Artifacts

1. **Original Draft Artifacts**
   - Basic Dockerfile (JAR-based)
   - Simple Helm charts
   - Basic Kubernetes manifests

2. **AI-Enhanced Artifacts**
   - Multi-stage Dockerfile with Tomcat support
   - Complete Helm charts with database integration
   - Enhanced Kubernetes manifests with proper configurations

3. **Key Improvements**
   - Database Support: Added PostgreSQL deployment with proper configuration
   - Health Checks: Added existing application health checks
   - Environment Variables: Configured database connection with secrets
   - Security: Added Kubernetes secrets management
   - Resource Management: Added configurable limits and requests

### Known Limitations and Workarounds

1. **Spring-Centric Design**
   - Draft assumes Spring Boot applications
   - Solution: AI-generated Tomcat-specific configurations

2. **Container Templates**
   - Limited Java container support
   - Solution: Enhanced multi-stage builds with proper base images

3. **Helm Chart Generation**
   - Basic manifest templates
   - Solution: AI-generated comprehensive charts

## Generated Kubernetes Resources

### Structure
```
k8s-simulation/helm/
├── Chart.yaml     # Chart metadata
├── values.yaml    # Configuration values
└── templates/     
    ├── deployment.yaml    # Tomcat application
    ├── service.yaml      # Service configuration
    ├── configmap.yaml    # Environment variables
    └── postgres.yaml     # Required database
```

### Key Features
- Tomcat-specific configuration
- PostgreSQL database integration
- Environment variable management
- Health check endpoints
- Resource specifications

## Project Structure

```
migration-draft/
├── deploytok8s.sh        # Main deployment script
├── k8s-simulation/       # AI-generated Kubernetes manifests
└── temp-after-container/ # Working directory (created during deployment)
    ├── src/             # Application source
    ├── pom.xml          # Build configuration
    ├── dockerfile       # AI-enhanced Dockerfile
    └── charts/         # Generated Helm charts
```