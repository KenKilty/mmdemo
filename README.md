# Legacy Java App Modernization Demo

This project simulates the real-world (ish) experience of migrating a legacy Java application to Kubernetes using open source tools from [Konveyor](https://konveyor.io/) and Microsoft's [Draft](https://draft.sh/). While we focus on a single todo application, this represents one instance of the challenges organizations face when modernizing hundreds or thousands of legacy applications. By working through a hands-on migration, we document the step-by-step process, challenges encountered, and opportunities for improving tooling support. Our goal is to explore how existing tools like Konveyor's analysis suite and Draft's scaffolding could be enhanced to better support Java application modernization at scale, particularly for organizations dealing with mass migration scenarios.

## Migration Experiences & Tool Analysis

Through this hands-on migration, we aim to understand the developer experience when using current open source modernization tools. By working with a representative Java application, we can identify where existing tools excel and where they could be enhanced to better support enterprise modernization needs. This exploration focuses on four key areas:

1. **Document Real Migration Experience**: Walk through the actual process of containerizing and deploying a legacy Java app to Kubernetes
2. **Evaluate Current Tools**: Test Konveyor's analysis capabilities and Draft's scaffolding support for Java applications
3. **Identify Tool Gaps**: Highlight areas where current tools could be enhanced to better support legacy Java migrations
4. **Explore Integration Possibilities**: Investigate how Konveyor's analysis could potentially enhance Draft's artifact generation

## Project Structure

This repository contains both the application code and all artifacts generated during our modernization journey. The structure reflects the actual chronological flow of the migration process - from analyzing the legacy application, through containerization guided by those findings, to deployment configuration and validation:

```
legacy-to-container/
├── before-container/       # Starting point: Legacy Java application
├── migration-konveyor/     # Analysis findings using Konveyor Kantra
├── after-container/        # AI-enhanced containerized version
├── migration-draft/        # Deployment artifacts for AKS
├── MIGRATION.md           # Migration journey narrative
└── README.md             # This file
```

Each component represents a phase in our modernization journey:

1. **Legacy Application** (`before-container/`):
   - Starting point: Traditional Java web application
   - Represents common enterprise patterns and challenges
   - See [before-container/README.md](before-container/README.md) for details

2. **Analysis Phase** (`migration-konveyor/`):
   - Analysis using Konveyor Kantra CLI for local assessment
   - Findings and recommendations that guided our containerization
   - See [migration-konveyor/README.md](migration-konveyor/README.md) for details

3. **Containerized Application** (`after-container/`):
   - Modernized version implementing analysis recommendations
   - Cloud-native adaptations guided by AI insights
   - See [after-container/README.md](after-container/README.md) for details

4. **Deployment Configuration** (`migration-draft/`):
   - Draft-generated Kubernetes artifacts enhanced with AI improvements
   - Demonstrates how Draft's output can be enhanced for legacy Java apps beyond current capability
   - Validated deployment configuration for AKS
   - See [migration-draft/README.md](migration-draft/README.md) for details

## Getting Started

1. Review [MIGRATION.md](MIGRATION.md) for the modernization journey narrative
2. Follow each component's README for detailed implementation steps
3. Use the provided scripts and configurations to test locally
4. Deploy to AKS using the Draft-based deployment process

## Technologies Used

- **Application**: Java, Tomcat, PostgreSQL
- **Containerization**: Podman, Docker
- **Analysis**: Konveyor Kantra
- **Deployment**: Draft, Kubernetes (AKS)
- **Infrastructure**: Terraform (Azure)

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.