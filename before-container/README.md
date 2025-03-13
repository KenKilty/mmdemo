# Legacy Todo Application (Pre-Containerization)

This is the legacy version of the Todo application, demonstrating an older 'legacy' Java web application practices and common antipatterns.

## Features

- Create, read, update, and delete todo items
- Filter todos by status (All, Active, Completed)
- Sort by creation date (Newest First, Oldest First)
- Track creation and completion timestamps for todos
- Responsive web interface
- Technical overview page

## Running the Application

### Prerequisites

- Java 8 or higher
- Maven 3.x

### Building and Running

```bash
../run-legacy.sh run
```

The application will be available at: <http://localhost:8080/legacy-todo>

### Debugging

```bash
../run-legacy.sh debug
```

Then in VS Code:

1. Set breakpoints in your code
2. Select "Debug Legacy Todo" configuration
3. Press F5

## Technical Details

### Architecture

```
Client Layer (Browser)
    │
    ▼
Presentation Layer (JSP)
    │    - index.jsp: Main UI
    │    - about.jsp: Technical overview
    │
    ▼
Controller Layer (Servlets)
    │    - TodoServlet: Handles all CRUD operations
    │
    ▼
Service Layer
    │    - TodoStorage: File-based storage service
    │
    ▼
Model Layer
    │    - Todo: Data model for todo items
    │
    ▼
Storage Layer
    │    - File System Storage (data/tasks.json)
```

### Common Anti-patterns

1. **File System Dependencies**: Direct file system access, hard coded paths, local file locking
2. **Local Caching**: Non-distributed cache, file system persistence, no cache coordination
3. **Configuration Management**: Properties files, hard coded values, no environment separation
4. **Logging Practices**: File-based logging, local log rotation, no structured logging
5. **Code Style Issues**: Inconsistent import ordering, missing documentation, non-standard formatting

### Implementation Details

1. **Local File Storage**: Tasks stored in `data/tasks.json` with direct file system access and no transaction support
2. **Embedded Cache**: Local in-memory EhCache with disk persistence in `data/cache/`
3. **Local File System Logging**: Logs written to `data/app.log` without rotation or centralization
4. **Local Configuration**: Property files in `src/main/resources` with hard coded paths

### Technical Stack

- **Runtime**: Java 8+, JSP 2.3.3, Servlet API 3.1.0
- **Build**: Maven 3.x
- **Dependencies**: JSTL 1.2, EhCache 2.10.6, Jackson 2.15.3, SLF4J/Logback
- **Quality Tools**: Maven Checkstyle Plugin with Google Java Style Guide

### Project Structure

```
legacy-todo/
├── src/
│   └── main/
│       ├── java/          # Java source files
│       ├── resources/     # Configuration files
│       └── webapp/        # Web resources and JSP pages
├── data/                  # Runtime data directory
│   ├── tasks.json        # Todo items storage
│   ├── cache/            # EhCache storage
│   └── app.log           # Application logs
├── pom.xml               # Maven configuration
└── checkstyle.xml        # Checkstyle configuration
```
