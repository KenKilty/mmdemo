# Legacy Java Application Modernization Journey

This document describes our journey of modernizing a legacy Java web application through a pragmatic, "just enough" approach to containerization. Rather than a complete rewrite, we focused on essential changes that enable cloud deployment while preserving the core application architecture.

## Architecture Changes

### Legacy Version
```
┌─────────────┐
│   Browser   │
└─────────────┘
       ↓
┌─────────────┐
│   Tomcat    │
│  (Embedded) │
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

### What We Changed
- **Data Layer**: File system to PostgreSQL for cloud-ready persistence
- **Configuration**: Environment variables for container-native configuration
- **Logging**: Container stdout/stderr with structured format
- **Monitoring**: Container-ready health checks and metrics

### What We Preserved
- Servlet/JSP architecture
- Traditional build process
- Existing application logic
- Core functionality

This pragmatic approach enables cloud deployment while minimizing risk and cost.

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
- 2GB+ free memory

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

The REST API remains largely compatible, with these enhancements:

1. **Base URL**
   - Legacy: `/legacy-todo/api`
   - Container: `/todo/api`

2. **New Features**
   - Health endpoint: `/todo/health`
   - Database status check
   - Connection pool metrics

### 4. Deployment

1. **Local Testing**
   ```bash
   # Run both versions for comparison
   ./run.sh legacy run
   ./run.sh container start

   # Verify functionality
   curl http://localhost:8080/legacy-todo     # Legacy
   curl http://localhost:18080/todo           # Container
   curl http://localhost:18080/todo/health    # Health check
   ```

2. **Production Deployment**
   ```bash
   cd after-container
   podman build -t todo-app .
   podman-compose up -d
   ```

## Lessons Learned

Our migration journey revealed insights about current open source tooling limitations and opportunities for improvement:

### Analysis Tool Enhancements
1. **Custom Rule Development**:
   - Need for additional Konveyor rules to detect common Java enterprise patterns
   - Custom rules required for:
     - Tomcat-specific configurations
     - Database connection management
     - Local file system dependencies
     - Application server specific deployment descriptors
   - Recommendation: Develop a comprehensive ruleset for Java enterprise applications

2. **Deployment Tool Gaps**:
   - Draft's Java template limitations:
     - No built-in support for WAR-based deployments
     - Missing Tomcat container configurations
     - Limited database service integration
     - Incomplete health check detection
   - Enhancement opportunities:
     - Template variations for different Java app servers
     - Database deployment patterns
     - Service discovery integration
     - Configuration management

3. **Manual Intervention Requirements**:
   - Several shell scripts needed for automation:
     - `deploytok8s.sh`: Enhanced deployment process with architecture compatibility fixes
     - `run.sh`: Local development workflow with unified command interface
     - Component-specific scripts for legacy and containerized versions
   - Areas requiring manual steps:
     - Database schema initialization
     - Service account configuration
     - Health check implementation
     - Resource limit tuning
   - **Recommendations for Kubernetes-Native Integration**:
     - Extend existing Konveyor Operator with modernization workflow:
       - Leverage existing operator lifecycle management
       - Add new CRDs to complement Tackle CR:
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

     - Integrate KAI Analysis Engine:
       - Connect KAI's rule engine with workflow steps
       - Extend analysis.Rules CRD for AI-enhanced scanning
       - Add AI-driven recommendation pipeline:
         - Pattern detection from legacy code
         - Suggested modernization actions
         - Impact assessment scoring
       - Store findings in Tackle Hub for tracking
       - Rinse and repeat with human in the loop

     - Add Draft Integration Controller:
       - Watch ModernizationWorkflow status
       - Trigger Draft template generation
       - Support iterative deployments:
         ```yaml
         apiVersion: tackle.konveyor.io/v1alpha1
         kind: ModernizationDeployment
         spec:
           iteration: "containerization"
           template: "java-tomcat"
           validation:
             healthChecks: true
             loadTests: true
           approval:
             required: true
             roles: ["architect", "developer"]
         ```

     - Enhanced Workflow Automation (The Dream):
       - Git-based change tracking
       - Automated PR generation
       - A/B deployment comparisons
       - Metrics collection and analysis
       - Human approval gates with Konveyor Hub UI integration

     - This integrated approach provides:
       - Native Kubernetes workflow management
       - Reuse of existing Konveyor and Draft components
       - Consistent operator-based lifecycle
       - Clear separation of concerns:
         - Analysis (KAI)
         - Workflow (Operator)
         - Deployment (Draft)
       - GitOps-friendly modernization process

4. **Development Workflow**:
   - Local testing environment setup
   - Parallel running of legacy and containerized versions (comparison and debugging)
   - Data migration procedures if needed
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