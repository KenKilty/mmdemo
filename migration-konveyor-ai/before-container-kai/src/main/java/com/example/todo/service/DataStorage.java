package com.example.todo.service;

import com.example.todo.model.Todo;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class DataStorage {
    private static final Logger logger = LoggerFactory.getLogger(DataStorage.class);
    private static final String DB_URL = System.getenv().getOrDefault("DB_URL", "jdbc:h2:mem:tododb;DB_CLOSE_DELAY=-1");
    private static HikariDataSource dataSource;

    public DataStorage() {
        initializeDataSource();
        createTodoTable();
    }

    private void initializeDataSource() {
        try {
            Properties props = new Properties();
            props.setProperty("cachePrepStmts", "true");
            props.setProperty("prepStmtCacheSize", "250");
            props.setProperty("prepStmtCacheSqlLimit", "2048");
            
            HikariConfig config = new HikariConfig(props);
            config.setJdbcUrl(DB_URL);
            // Configure other properties as needed
            config.setMaximumPoolSize(10);
            config.setMinimumIdle(5);
            config.setIdleTimeout(300000);
            config.setConnectionTimeout(20000);
            
            dataSource = new HikariDataSource(config);
            logger.info("Database connection pool initialized");
        } catch (Exception e) {
            logger.error("Failed to initialize database connection pool", e);
            throw new RuntimeException("Database initialization failed", e);
        }
    }

    private void createTodoTable() {
        String sql = "CREATE TABLE IF NOT EXISTS todos ("
            + "id BIGINT PRIMARY KEY AUTO_INCREMENT,"
            + "title VARCHAR(255) NOT NULL,"
            + "description TEXT,"
            + "completed BOOLEAN DEFAULT FALSE,"
            + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
            + "completed_at TIMESTAMP"
            + ")";
        
        try (Connection conn = getConnection();
             Statement stmt = conn.createStatement()) {
            stmt.execute(sql);
            logger.info("Todo table created or verified");
        } catch (SQLException e) {
            logger.error("Failed to create todo table", e);
            throw new RuntimeException("Table creation failed", e);
        }
    }

    public Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }

    public List<Todo> loadTodos() {
        List<Todo> todos = new ArrayList<>();
        String sql = "SELECT * FROM todos ORDER BY created_at DESC";
        
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            while (rs.next()) {
                Todo todo = new Todo();
                todo.setId(rs.getLong("id"));
                todo.setTitle(rs.getString("title"));
                todo.setDescription(rs.getString("description"));
                todo.setCompleted(rs.getBoolean("completed"));
                todo.setCreatedAt(rs.getTimestamp("created_at"));
                todo.setCompletedAt(rs.getTimestamp("completed_at"));
                todos.add(todo);
            }
            logger.debug("Loaded {} todos from database", todos.size());
            return todos;
        } catch (SQLException e) {
            logger.error("Failed to load todos", e);
            throw new RuntimeException("Failed to load todos", e);
        }
    }

    public Todo addTodo(Todo todo) {
        String sql = "INSERT INTO todos (title, description, completed) VALUES (?, ?, ?)";
        
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            stmt.setString(1, todo.getTitle());
            stmt.setString(2, todo.getDescription());
            stmt.setBoolean(3, todo.isCompleted());
            
            int affectedRows = stmt.executeUpdate();
            if (affectedRows == 0) {
                throw new SQLException("Creating todo failed, no rows affected.");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    todo.setId(generatedKeys.getLong(1));
                    logger.debug("Created new todo with id: {}", todo.getId());
                    return todo;
                } else {
                    throw new SQLException("Creating todo failed, no ID obtained.");
                }
            }
        } catch (SQLException e) {
            logger.error("Failed to add todo", e);
            throw new RuntimeException("Failed to add todo", e);
        }
    }

    public void updateTodo(Todo todo) {
        String sql = "UPDATE todos SET title = ?, description = ?, completed = ?, completed_at = ? WHERE id = ?";
        
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, todo.getTitle());
            stmt.setString(2, todo.getDescription());
            stmt.setBoolean(3, todo.isCompleted());
            stmt.setTimestamp(4, todo.isCompleted() ? new Timestamp(System.currentTimeMillis()) : null);
            stmt.setLong(5, todo.getId());
            
            int affectedRows = stmt.executeUpdate();
            if (affectedRows == 0) {
                throw new SQLException("Updating todo failed, no rows affected.");
            }
            logger.debug("Updated todo with id: {}", todo.getId());
        } catch (SQLException e) {
            logger.error("Failed to update todo", e);
            throw new RuntimeException("Failed to update todo", e);
        }
    }

    public void deleteTodo(Long id) {
        String sql = "DELETE FROM todos WHERE id = ?";
        
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setLong(1, id);
            int affectedRows = stmt.executeUpdate();
            if (affectedRows == 0) {
                throw new SQLException("Deleting todo failed, no rows affected.");
            }
            logger.debug("Deleted todo with id: {}", id);
        } catch (SQLException e) {
            logger.error("Failed to delete todo", e);
            throw new RuntimeException("Failed to delete todo", e);
        }
    }
} 