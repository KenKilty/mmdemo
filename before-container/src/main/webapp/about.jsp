<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>About - Legacy Todo App</title>
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
    </style>
</head>
<body>
    <div class="back-link">
        <a href="index.jsp">← Back to Application</a>
    </div>

    <h1>About Legacy Todo Application</h1>

    <div class="section">
        <h2>Dependencies and Versions</h2>
        
        <div class="dependency">
            <h3>Runtime Environment</h3>
            <ul>
                <li>Java Version: <%= System.getProperty("java.version") %></li>
                <li>Servlet Container: <%= application.getServerInfo() %></li>
                <li>Java Server Pages (JSP): 2.3.3</li>
                <li>Servlet API: 3.1.0</li>
            </ul>
        </div>

        <div class="dependency">
            <h3>Core Dependencies</h3>
            <ul>
                <li>JSTL (JavaServer Pages Standard Tag Library): 1.2</li>
                <li>EhCache: 2.10.6</li>
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
            <p>The application follows a traditional Java web application architecture with the following components:</p>
            
            <pre>
Client Layer (Browser)
    │
    ▼
Presentation Layer (JSP)
    │    - index.jsp: Main UI
    │    - about.jsp: Application information
    │
    ▼
Controller Layer (Servlets)
    │    - TodoServlet: Handles all CRUD operations
    │
    ▼
Service Layer
    │    - TodoCache: Caching service using EhCache
    │    - TodoStorage: File-based storage service
    │
    ▼
Model Layer
    │    - Todo: Data model for todo items
    │
    ▼
Storage Layer
    │    - File System Storage (data/tasks.json)
    │    - Cache Storage (data/cache/)</pre>

            <h3>Key Components:</h3>
            <ul>
                <li><strong>Frontend:</strong> Pure JavaScript for dynamic updates, Fetch API for AJAX calls</li>
                <li><strong>Backend:</strong> Java Servlets for REST API endpoints</li>
                <li><strong>Data Flow:</strong> Browser → JSP → Servlet → Cache/Storage → JSON Response</li>
                <li><strong>Caching:</strong> Two-level caching with memory and disk persistence</li>
                <li><strong>Storage:</strong> JSON file-based storage with atomic operations</li>
            </ul>

            <h3>Legacy Characteristics:</h3>
            <ul>
                <li>File-based storage instead of a database</li>
                <li>Local disk caching with EhCache</li>
                <li>Properties file configuration</li>
                <li>File system logging</li>
            </ul>
        </div>
    </div>

    <div class="version-info">
        Tomcat Version: <%= application.getServerInfo() %><br>
        Java Version: <%= System.getProperty("java.version") %>
    </div>
</body>
</html> 