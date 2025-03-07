# Legacy Todo Application (Pre-Containerization)

This is the legacy version of the Todo application, demonstrating traditional Java web application practices and common anti-patterns.

## Features
- Create, read, update, and delete todo items
- Filter todos by status (All, Active, Completed)
- Sort by creation date (Newest First, Oldest First)
- Track creation and completion timestamps for todos
- Responsive web interface
- Technical overview page

## Architecture

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

## Legacy Implementation Details

### 1. Local File Storage
- Tasks stored in `data/tasks.json`
- Direct filesystem access
- No transaction support
- Local file locking

### 2. Embedded Cache (EhCache)
- Local in-memory cache
- Disk persistence in `data/cache/`
- Cache files:
  - `.data` files: cached items
  - `.index` files: lookup operations
  - `.control` files: metadata

### 3. Local File System Logging
- Logs written to `data/app.log`
- Basic logging without rotation
- No centralized logging

### 4. Local Configuration
- Properties files in `src/main/resources`
- Hardcoded paths
- Environment-specific settings in files

## Technical Stack

### Runtime Environment
- Java 8 or higher
- Maven 3.x
- Java Server Pages (JSP): 2.3.3
- Servlet API: 3.1.0

### Dependencies
- JSTL: 1.2
- EhCache: 2.10.6
- Jackson: 2.15.3
- SLF4J: 1.7.30
- Logback: 1.2.3
- Checkstyle: 3.3.1 (Google Style Guide)

### Code Quality Tools
- Maven Checkstyle Plugin
- Google Java Style Guide compliance
- Automated code style validation

## Project Structure
```
legacy-todo/
├── src/
│   └── main/
│       ├── java/          # Java source files
│       ├── resources/     # Configuration files
│       └── webapp/        # Web resources and JSP pages
├── data/                  # Runtime data directory
│   ├── tasks.json        # Todo items storage
│   └── app.log           # Application logs
├── pom.xml               # Maven configuration
└── checkstyle.xml        # Checkstyle configuration
```

## Running the Application

### Prerequisites
- Java 8 or higher
- Maven 3.x

### Building and Running
```bash
../run-legacy.sh
```

The application will be available at: http://localhost:8080/legacy-todo

### Debugging
```bash
../run-legacy.sh debug
```

Then in VS Code:
1. Set breakpoints in your code
2. Select "Debug Legacy Todo" configuration
3. Press F5

## Known Anti-patterns

1. **File System Dependencies**
   - Direct file system access
   - Hardcoded paths
   - Local file locking

2. **Local Caching**
   - Non-distributed cache
   - File system persistence
   - No cache coordination

3. **Configuration Management**
   - Properties files
   - Hardcoded values
   - No environment separation

4. **Logging Practices**
   - File-based logging
   - Local log rotation
   - No structured logging

5. **Code Style Issues**
   - Inconsistent import ordering
   - Missing documentation
   - Non-standard indentation
   - Long lines exceeding 100 characters 