package com.example.todo.listener;

import com.example.todo.service.TodoStorage;
import com.example.todo.servlet.HealthCheckServlet;
import com.example.todo.servlet.TodoServlet;
import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.ServletRegistration;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Context listener for initializing and cleaning up Todo application resources.
 */
public class TodoContextListener implements ServletContextListener {
    private static final Logger logger = LoggerFactory.getLogger(TodoContextListener.class);
    private TodoStorage storage;
    private Connection connection;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        logger.info("Initializing Todo application context");
        
        try {
            // Load PostgreSQL driver
            Class.forName("org.postgresql.Driver");
            logger.info("PostgreSQL driver loaded");

            // Initialize database connection
            String dbHost = System.getenv("DB_HOST");
            String dbPort = System.getenv("DB_PORT");
            String dbName = System.getenv("DB_NAME");
            String dbUser = System.getenv("DB_USER");
            String dbPassword = System.getenv("DB_PASSWORD");
            
            String url = String.format("jdbc:postgresql://%s:%s/%s", dbHost, dbPort, dbName);
            connection = DriverManager.getConnection(url, dbUser, dbPassword);
            logger.info("Database connection established");
            
            // Initialize storage with connection
            storage = new TodoStorage(connection);
            storage.initializeDatabase();

            ServletContext context = sce.getServletContext();
            context.setAttribute("todoStorage", storage);

            // Register TodoServlet
            TodoServlet todoServlet = new TodoServlet();
            ServletRegistration.Dynamic todoRegistration = context.addServlet("TodoServlet", todoServlet);
            todoRegistration.addMapping("/api/todos/*");
            logger.info("Todo API endpoint registered at /api/todos/*");

            // Register health check servlet
            HealthCheckServlet healthCheckServlet = new HealthCheckServlet();
            ServletRegistration.Dynamic registration = context.addServlet("healthCheck", healthCheckServlet);
            registration.addMapping("/health");
            logger.info("Health check endpoint registered at /health");
        } catch (SQLException e) {
            logger.error("Failed to initialize database connection", e);
            throw new RuntimeException("Failed to initialize database connection", e);
        } catch (ClassNotFoundException e) {
            logger.error("Failed to load PostgreSQL driver", e);
            throw new RuntimeException("Failed to load PostgreSQL driver", e);
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        logger.info("Destroying Todo application context");
        if (storage != null) {
            storage.close();
        }
        if (connection != null) {
            try {
                connection.close();
                logger.info("Database connection closed");
            } catch (SQLException e) {
                logger.error("Failed to close database connection", e);
            }
        }
        logger.info("Todo application context destroyed");
    }
} 