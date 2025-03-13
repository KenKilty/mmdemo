# Containerized Todo Application

This is a pragmatically modernized version of the Todo application, demonstrating a "just enough" approach to containerization that minimizes changes while enabling cloud deployment. This approach mirrors real-world enterprise scenarios where complete rewrites are often impractical, and incremental modernization is preferred.

## Features

- Create, read, update, and delete todo items
- Filter todos by status (All, Active, Completed)
- Sort by creation date (Newest First, Oldest First)
- Track creation and completion timestamps for todos
- Responsive web interface
- Health check endpoint for monitoring
- Container-native design
- Technical overview page

## Running the Application

### Prerequisites

- Podman or Docker
- curl (for health checks)

### Building and Running

```bash
../run.sh container start
```

The application will be available at: <http://localhost:18080/todo>
Health check endpoint: <http://localhost:18080/todo/health>

### Debugging

```bash
../run.sh container debug
```

Then in VS Code:

1. Set breakpoints in your code
2. Select "Debug Containerized Todo" configuration
3. Press F5

## Modernization Philosophy

This version demonstrates a pragmatic approach to containerization that:

- Minimizes code changes while enabling cloud deployment
- Preserves existing application architecture
- Focuses on infrastructure modernization over application modernization
- Balances modernization benefits with risk and effort

### What We Changed

- Replaced file storage with PostgreSQL
- Removed local caching in favor of stateless design
- Moved configuration to environment variables
- Updated logging for container compatibility
- Added health monitoring

### What We Intentionally Kept

- **Servlet/JSP Architecture**: Maintained traditional Java web application structure
- **Tomcat Server**: Kept the familiar servlet container
- **JSP Views**: Preserved JSP-based views
- **Traditional Build Process**: Maintained Maven-based build
- **Basic Error Handling**: Kept simple error handling
- **Simple Authentication**: Maintained basic security

### What We Could Have Modernized Further

- **Framework**: Migration to Spring Boot for modern dependency injection
- **Frontend**: Adoption of React/Vue.js for a more dynamic UI
- **API Design**: Implementation of OpenAPI/Swagger for documentation
- **Testing**: Comprehensive test coverage with modern frameworks
- **Security**: Implementation of OAuth2/JWT for authentication
- **Monitoring**: Addition of Prometheus/Grafana for metrics
- **CI/CD**: Implementation of modern CI/CD pipelines
- **Build Tools**: Adoption of Gradle or modern build systems

## Technical Details

### Architecture

```text
Client Layer (Browser)
    │
    ▼
Presentation Layer (JSP)
    │    - index.jsp: Main UI
    │    - error.jsp: Error handling
    │    - about.jsp: Technical overview
    │
    ▼
Controller Layer (Servlets)
    │    - TodoServlet: Handles CRUD operations
    │    - HealthCheckServlet: Application health monitoring
    │
    ▼
Service Layer
    │    - TodoStorage: PostgreSQL-based storage service
    │
    ▼
Model Layer
    │    - Todo: Data model for todo items
    │
    ▼
Storage Layer
    │    - PostgreSQL Database (Containerized)
```

### Key Improvements

1. **Database-Driven Storage**: PostgreSQL replaces file-based storage with proper transaction management and scalability
2. **Stateless Architecture**: Container-ready design with horizontal scalability
3. **Container Configuration**: Environment variables for configuration with no hardcoded values
4. **Modern Logging**: Container-native logging with structured formats for aggregation
5. **Code Quality**: Consistent styling with automated validation

### Technical Stack

- **Runtime**: Java 17, Tomcat 9
- **Database**: PostgreSQL 16
- **Build**: Maven 3.9
- **Dependencies**: Servlet API 3.1.0, PostgreSQL JDBC 42.7.2, HikariCP 5.1.0, Jackson 2.15.3, SLF4J/Logback

### Configuration

The application uses the following environment variables:

- `DB_HOST`: PostgreSQL host (default: postgres)
- `DB_PORT`: PostgreSQL port (default: 5432)
- `DB_NAME`: Database name (default: todo)
- `DB_USER`: Database user (default: todo)
- `DB_PASSWORD`: Database password (default: todo)
- `DB_POOL_SIZE`: Connection pool size (default: 10)
- `DB_POOL_TIMEOUT`: Connection timeout in ms (default: 30000)
- `HEALTH_CHECK_INTERVAL`: Health check interval in ms (default: 60000)

### Project Structure

```text
after-container/
├── src/
│   └── main/
│       ├── java/          # Java source files
│       ├── resources/     # Configuration files
│       └── webapp/        # Web resources and JSP pages
├── podman/                # Container configuration
│   ├── tomcat/           # Tomcat configuration
│   └── postgres/         # PostgreSQL configuration
├── podman-compose.yml    # Container orchestration
└── pom.xml              # Maven configuration
```
