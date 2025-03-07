<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>About - Containerized Todo App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        .back-link {
            margin-bottom: 20px;
        }
        .back-link a {
            color: #2196f3;
            text-decoration: none;
        }
        .back-link a:hover {
            text-decoration: underline;
        }
        .section {
            margin: 20px 0;
            padding: 20px;
            background-color: #f5f5f5;
            border-radius: 5px;
        }
        .dependency {
            margin: 10px 0;
            padding: 10px;
            background-color: white;
            border: 1px solid #ddd;
            border-radius: 3px;
        }
        .architecture-text {
            line-height: 1.6;
        }
        pre {
            background-color: #f8f8f8;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        .improvements {
            margin: 10px 0;
            padding: 15px;
            background-color: white;
            border: 1px solid #ddd;
            border-radius: 3px;
        }
        .improvements h3 {
            color: #2196f3;
            margin-top: 0;
        }
    </style>
</head>
<body>
    <div class="back-link">
        <a href="index.jsp">← Back to Application</a>
    </div>

    <h1>About Containerized Todo Application</h1>

    <div class="section">
        <h2>Dependencies and Versions</h2>
        
        <div class="dependency">
            <h3>Runtime Environment</h3>
            <ul>
                <li>Java Version: <%= System.getProperty("java.version") %></li>
                <li>Servlet Container: <%= application.getServerInfo() %></li>
                <li>PostgreSQL: 16</li>
                <li>Servlet API: 3.1.0</li>
            </ul>
        </div>

        <div class="dependency">
            <h3>Core Dependencies</h3>
            <ul>
                <li>PostgreSQL JDBC Driver: 42.7.2</li>
                <li>HikariCP Connection Pool: 5.1.0</li>
                <li>Jackson (JSON Processing): 2.15.3</li>
            </ul>
        </div>

        <div class="dependency">
            <h3>Logging Dependencies</h3>
            <ul>
                <li>SLF4J API: 1.7.30</li>
                <li>Logback Classic: 1.2.3</li>
            </ul>
        </div>
    </div>

    <div class="section">
        <h2>Application Architecture</h2>
        <div class="architecture-text">
            <p>The application follows a modern, containerized architecture with the following components:</p>
            
            <pre>
Client Layer (Browser)
    │
    ▼
Presentation Layer (JSP)
    │    - index.jsp: Main UI
    │    - error.jsp: Error handling
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
    │    - PostgreSQL Database (Containerized)</pre>

            <h3>Key Components:</h3>
            <ul>
                <li><strong>Frontend:</strong> Pure JavaScript for dynamic updates, Fetch API for AJAX calls</li>
                <li><strong>Backend:</strong> Java Servlets for REST API endpoints</li>
                <li><strong>Data Flow:</strong> Browser → JSP → Servlet → PostgreSQL → JSON Response</li>
                <li><strong>Database:</strong> PostgreSQL with connection pooling</li>
                <li><strong>Health Check:</strong> Dedicated endpoint for monitoring</li>
            </ul>
        </div>
    </div>

    <div class="section">
        <h2>Improvements Over Legacy Version</h2>

        <div class="improvements">
            <h3>Database-Driven Storage</h3>
            <ul>
                <li>PostgreSQL replaces file-based storage</li>
                <li>Full transaction support</li>
                <li>Proper data consistency</li>
                <li>Connection pooling with HikariCP</li>
            </ul>
        </div>

        <div class="improvements">
            <h3>Stateless Architecture</h3>
            <ul>
                <li>No local caching dependencies</li>
                <li>Container-ready design</li>
                <li>Horizontally scalable</li>
                <li>No shared file system needs</li>
            </ul>
        </div>

        <div class="improvements">
            <h3>Container Configuration</h3>
            <ul>
                <li>Environment variables for configuration</li>
                <li>No hardcoded values</li>
                <li>Clear separation of concerns</li>
                <li>Runtime environment configuration</li>
            </ul>
        </div>

        <div class="improvements">
            <h3>Modern Logging</h3>
            <ul>
                <li>Container stdout/stderr logging</li>
                <li>JSON-formatted logs</li>
                <li>Structured logging with SLF4J/Logback</li>
                <li>Ready for log aggregation</li>
            </ul>
        </div>
    </div>

    <div class="version-info">
        Tomcat Version: <%= application.getServerInfo() %><br>
        Java Version: <%= System.getProperty("java.version") %>
    </div>
</body>
</html> 