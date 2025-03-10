# Modernizing a Legacy Java Application

## Introduction

Welcome to my journey of modernizing a legacy Java application. In this project, I set out to modernize an old-school pre-container Java application, updating "just enough" of the app to allow it to run in a container and capable of running on Kubernetes.

I wanted to modernize the app without completely rewriting it. I wanted to keep its core functionality intact while making minimal changes to adapt it for Kubernetes, reflecting reality for migration and modernization in most enterprises. Get the legacy app working in Kubernetes with minimal effort and time investment until it can be retired or replaced. I wanted to explore a hypothesis: Could I leverage a combination of static code analysis with Konveyor, artifact generation with Draft, and AI chat to automate the migration process?

I began by creating a version of the app that mimicked typical pre-container Java legacy practices. Then, I turned to AI (Claude 3.5) to help quickly modernize just enough of it and get it working locally as a container. After this, I ran static code analysis using Konveyor Kantra to see if it could identify the legacy practices I had introduced. I wanted to see the output of Kantra was enough to replace the prompts I had used while I modernized the app with AI Chat in VSCode. I also wanted to used Draft to generate deployment artifacts and compared the results with what I built with AI Chat to deploy the modified app with docker-compose and podman locally.

Throughout the journey, I gained insights into the strengths and limitations of these tools. While they show promise, I found that human oversight is still crucial to ensure everything runs smoothly. Still, I got pretty close using the tools comparing it to what I built manually with AI chat which is encouraging that the end to end process could be automated with a workflow. My ultimate vision would be to develop a Kubernetes-native solution that can help other enterprises modernize their apps with minimal hassle at scale.

Let's dive into the details of how I tackled each part of this project.

# Legacy Java Application Modernization Journey

This document describes our journey of modernizing a legacy Java web application through a pragmatic, "just enough" approach to containerization. Rather than a complete rewrite, I focused on essential changes that enable cloud deployment while preserving the core application architecture. Our goal was to demonstrate a feasible path for enterprises to modernize their applications with minimal disruption.

## Legacy Application Setup

The sample legacy application was designed to mimic a typical Java monolith running on a VM in an enterprise setting. It utilized known legacy practices, such as embedded Tomcat and local file storage, which posed challenges for containerization. The local development experience was intended to simulate the starting point of a migration effort, providing a realistic scenario for modernization. For more details, refer to the [before-container/README.md](before-container/README.md).

## Modernization Process

I employed AI assistance to jump directly to a modernized version of the application, addressing legacy practices before running static code analysis with Konveyor. This approach allowed us to test Konveyor Kantra's ability to identify non-cloud-ready practices. The modernized version is detailed in the [after-container/README.md](after-container/README.md).

- **Key Changes**:
  - Data Layer: Transitioned from file system to PostgreSQL for cloud-ready persistence.
  - Configuration: Adopted environment variables for container-native configuration.
  - Logging: Implemented structured logging to container stdout/stderr.
  - Monitoring: Added container-ready health checks and metrics.

- **Preserved Elements**:
  - Servlet/JSP architecture
  - Traditional build process
  - Existing application logic

## Static Code Analysis with Konveyor Kantra

After modernizing the application "just enough," I ran Konveyor Kantra to discover gaps using the out-of-the-box target 'cloud readiness'. I needed to add custom rules to find all necessary changes but I was able to identify all the issues that were purposefully introduced in the original version of the app. The analysis report was used to generate code fixes, comparing interactive AI modernization with batch AI modernization using Konveyor Kantra. This sounds fancy but all that was really done was use the analysis results as prompts with the same AI chat to compare it's recommended code changes with the changes I made during building containerized version of the sample. This approach highlighted the potential for automated code generation based on static analysis findings. It was not perfect but close enough.

## Deployment to AKS with Draft

I compared human-in-the-loop AI for creating deployment artifacts with batch modernization using the Draft CLI. Challenges with Draft's dockerfile and helm charts were addressed using AI to refine these artifacts for AKS deployment. This process demonstrated the effectiveness of combining AI with existing tools to overcome limitations and achieve successful deployment. Put another way, I used AI chat to compare the local setup in running the containerized version of the app (docker-compose, dockerfile) with the Draft artifacts to determine was what missing from the Draft artifacts and noted the limitations of current Draft asset generation.

## Hypothesis and Future Vision

The hypothesis of automating the migration process using static code analysis, artifact generation, and AI support was proven successful with deployment to AKS but with the understanding that my sample app was fairly simple. The vision is to create a Kubernetes-native solution that encompasses all capabilities described in the migration journey, supporting mass migration with human oversight. Fortunately, this kind of work is already underway with the Konveyor AI (KAI) project but artifact generation still remains a gap that Draft+AI could help address.

## Integration Opportunities

There is potential to combine Konveyor analysis with Draft to select appropriate templates, configure health checks, and generate resource configurations. Leveraging generative AI can extend beyond current functionality, offering a more complete and assistive modernization solution.

- **Opportunities**:
  - Combine Konveyor analysis with Draft
  - Configure health checks
  - Generate resource configurations
- **Tooling Limitations**:
  - Limited database integration
  - Incomplete health check detection
- **AI Code Generation**:
  - Used Claude 3.5 for artifact refinement
  - Compared Draft outputs with AI-generated docker-compose files

## Architecture Changes

### Legacy Version
```
┌─────────────┐
│   Browser   │
└─────────────┘
       ↓
┌─────────────┐
│   Tomcat    │
│  (Server) │
└─────────────┘
       ↓
┌─────────────┐
│  EhCache    │
│ (Local File)│
└─────────────┘
       ↓
┌─────────────┐
│ File System │
│  (JSON)     │
└─────────────┘
```

### Containerized Version
```
┌─────────────┐
│   Browser   │
└─────────────┘
       ↓
┌─────────────┐
│   Tomcat    │
│  Container  │
└─────────────┘
       ↓
┌─────────────┐
│ PostgreSQL  │
│  Container  │
└─────────────┘
```

## Modernization Approach

Our approach focused on minimal-risk changes that enable containerization while preserving core functionality:

### What Was Changed
- **Data Layer**: File system to PostgreSQL for cloud-ready persistence
- **Configuration**: Environment variables for container-native configuration
- **Logging**: Container stdout/stderr with structured format
- **Monitoring**: Container-ready health checks and metrics

### What Was Preserved
- Servlet/JSP architecture
- Traditional build process
- Existing application logic
- Core functionality

## Migration Process

### 1. Development Environment Setup

#### Legacy Requirements:
- Java 8+
- Maven 3.x
- Local file system access

#### Container Requirements:
- Java 17+
- Podman 5.0.0+
- Podman Compose

### 2. Configuration Changes

#### Environment Variables
| Legacy | Containerized | Default | Description |
|--------|--------------|---------|-------------|
| N/A | DB_HOST | postgres | PostgreSQL host |
| N/A | DB_PORT | 5432 | PostgreSQL port |
| N/A | DB_NAME | todo | Database name |
| N/A | DB_USER | todo | Database user |
| N/A | DB_PASSWORD | todo | Database password |
| N/A | DB_POOL_SIZE | 10 | Connection pool size |
| N/A | DB_POOL_TIMEOUT | 30000 | Connection timeout (ms) |
| N/A | HEALTH_CHECK_INTERVAL | 60000 | Health check interval (ms) |

### 3. API Changes

The REST API remains largely compatible, with these minor enhancements:

1. **Base URL**
   - Legacy: `/legacy-todo/api`
   - Container: `/todo/api`

2. **New Features**
   - Health endpoint: `/todo/health`
   - Database Storage `/todo/api/todos CRUD`
   - Database status check via health endpoint

## Lessons Learned

Our migration journey revealed insights about current migration open source tooling limitations and opportunities for improvement:

### Analysis Tool Enhancements
1. **Custom Rule Development**:
   - Need for additional Konveyor rules to detect common Java enterprise patterns
   - Custom rules required for:
     - Tomcat-specific configurations
     - Database connection management
     - Local file system dependencies
     - Application server specific deployment descriptors
   - Recommendation: Contribute and help improve the in-box Konveyor Kantra cloud-readiness target ruleset.

2. **Artifact Generation Tool Gaps**:
  - Draft's Java template limitations:
    - Limited database service integration
    - Incomplete health check detection
    - Single-stage build leading to larger image sizes
    - Use of generic base image instead of specific runtime images (e.g., Tomcat)
    - Direct JAR file execution instead of WAR deployment
    - Lack of additional tools like curl for HTTP operations
    - Absence of explicit database driver inclusion for connectivity
  - Enhancement opportunities for Draft:
    - Template variations for different Java app servers
    - Database deployment patterns
    - Configuration management
    - Multi-stage build for optimized image size
    - Specific base image for runtime (e.g., Tomcat for Java web apps)
    - Application deployment as WAR files to application servers
    - Inclusion of additional tools like curl for HTTP operations
    - Explicit handling of database drivers for connectivity

   **Addressing Limitations with AI Code Generation**:
   To overcome the limitations of the AKS draft artifact generation, I employed AI code generation via Claude. This approach involved comparing the Draft generated artifacts with an AI-generated docker-compose file located in the after-container directory. By analyzing the requirements for a full local deployment through docker-compose and the after-container codebase, I was able to refine the Dockerfile and other deployment artifacts, and tested via a deployment to AKS managed by the deploytok8s.sh script (which also outputs where the hacks took place with the end to end scenario).

3. **Recommendations for Kubernetes-Native Integration with Konveyor/Draft**:
    - Extend existing Konveyor Operator with modernization workflow to enable sending analysis report results to Draft or comparable capability:
      - Leverage existing operator lifecycle management
      - Add new CRD to complement Tackle CRD something like:
        ```yaml
        apiVersion: tackle.konveyor.io/v1alpha1
        kind: ModernizationWorkflow
        spec:
          source:
            repository: "https://github.com/user/legacy-app"
            branch: "main"
          analysis:
            rules: ["java-ee", "database", "security"]
            aiAssistance: true
          iterations:
            - name: "initial-assessment"
            - name: "containerization"
            - name: "cloud-native-services"
        ```
     - Integrate Konveyor Kantra Analysis Engine:
       - Connect Kantra analysis with workflow steps
       - Extend analysis.Rules CRD for AI-enhanced scanning

     - AI-Driven Recommendation Tool such as Konveyor AI (KAI):
       - **Purpose**: Assist developers in modernizing applications "just enough" based on current capabilities
       - **Current Integration**: Bound to VS Code via an extension ([getting started](https://github.com/konveyor/kai/blob/main/docs/getting_started.md))
       - **Potential to use KAI as a Service**:
         - Leverage analysis output from Konveyor analysis engine
         - Available in Konveyor Hub when deployed on k8s
       - **Features**:
         - Pattern detection from legacy code
         - Suggested modernization actions
         - Impact assessment scoring
         - Human-in-the-loop for validation and iteration
       - **Future Enhancements**:
         - Expand to other IDEs and platforms
         - Develop standalone service for broader accessibility

     - Store findings in Konveyor Hub for tracking
     - Rinse and repeat with human in the loop

4. **Development Workflow**:
   - Local testing environment setup
   - Parallel running of legacy and containerized versions (comparison and debugging)
   - Local debug mode configurations

### Integration Opportunities
- Potential to combine Konveyor analysis with Draft:
  - Use analysis findings to select appropriate templates
  - Automatically configure health checks
  - Generate appropriate resource configurations
  - Customize deployment artifacts based on detected patterns
  - Leverage gen AI to extend beyond the limits of current functionality

## Support and Troubleshooting

### Documentation
- **Component Documentation**:
  - [before-container/README.md](before-container/README.md): Legacy application setup
  - [after-container/README.md](after-container/README.md): Containerized version
  - [migration-draft/README.md](migration-draft/README.md): Kubernetes deployment
- **External Tools**:
  - [Podman Documentation](https://docs.podman.io/)
  - [PostgreSQL Documentation](https://www.postgresql.org/docs/)

### Common Issues
1. **Application Health**:
   - Check endpoint: `/todo/health`
   - Review logs: `./run.sh container logs`
   - Verify database connectivity
   - Consult architecture diagrams

2. **Environment Setup**:
   - Validate configurations
   - Check resource requirements
   - Verify service dependencies

3. **Deployment**:
   - Validate Kubernetes configs
   - Check container builds
   - Monitor resource usage 