package com.example.todo.service;

import com.example.todo.model.Todo;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Service class for managing Todo items in a PostgreSQL database.
 */
public class TodoStorage {
    private static final Logger logger = LoggerFactory.getLogger(TodoStorage.class);
    private final Connection connection;

    /**
     * Initializes TodoStorage with a database connection.
     *
     * @param connection The database connection to use
     */
    public TodoStorage(Connection connection) {
        this.connection = connection;
        initializeDatabase();
    }

    /**
     * Checks the health of the database connection.
     * 
     * @throws SQLException if the database connection is not healthy
     */
    public void checkHealth() throws SQLException {
        try (Statement stmt = connection.createStatement()) {
            stmt.execute("SELECT 1");
        } catch (SQLException e) {
            logger.error("Database health check failed", e);
            throw e;
        }
    }

    /**
     * Creates the todos table if it doesn't exist.
     */
    public void initializeDatabase() {
        String createTableQuery = "CREATE TABLE IF NOT EXISTS todos ("
            + "id SERIAL PRIMARY KEY,"
            + "title VARCHAR(255) NOT NULL,"
            + "description TEXT,"
            + "completed BOOLEAN DEFAULT FALSE,"
            + "created_at TIMESTAMP NOT NULL,"
            + "completed_at TIMESTAMP)";

        try (Statement stmt = connection.createStatement()) {
            stmt.execute(createTableQuery);
            logger.info("Database initialized successfully");
        } catch (SQLException e) {
            logger.error("Failed to initialize database", e);
            throw new RuntimeException("Failed to initialize database", e);
        }
    }

    /**
     * Retrieves all Todo items from the database.
     *
     * @return list of all Todo items
     */
    public List<Todo> getAllTodos() {
        List<Todo> todos = new ArrayList<>();
        String query = "SELECT * FROM todos ORDER BY created_at DESC";

        try (PreparedStatement stmt = connection.prepareStatement(query);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Todo todo = new Todo();
                todo.setId(rs.getInt("id"));
                todo.setTitle(rs.getString("title"));
                todo.setDescription(rs.getString("description"));
                todo.setCompleted(rs.getBoolean("completed"));
                todo.setCreatedAt(rs.getTimestamp("created_at").getTime());
                java.sql.Timestamp completedAt = rs.getTimestamp("completed_at");
                if (rs.wasNull()) {
                    todo.setCompletedAt(null);
                } else {
                    todo.setCompletedAt(completedAt.getTime());
                }
                todos.add(todo);
            }
        } catch (SQLException e) {
            logger.error("Failed to retrieve todos", e);
            throw new RuntimeException("Failed to retrieve todos", e);
        }

        return todos;
    }

    /**
     * Creates a new Todo item in the database.
     *
     * @param todo the Todo item to create
     * @return the created Todo item with its generated ID
     */
    public Todo createTodo(Todo todo) {
        String query = 
            "INSERT INTO todos (title, description, completed, created_at, completed_at) "
            + "VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement stmt = connection.prepareStatement(query, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setString(1, todo.getTitle());
            stmt.setString(2, todo.getDescription());
            stmt.setBoolean(3, todo.isCompleted());
            stmt.setTimestamp(4, new java.sql.Timestamp(todo.getCreatedAt()));

            if (todo.isCompleted()) {
                stmt.setTimestamp(5, new java.sql.Timestamp(todo.getCompletedAt()));
            } else {
                stmt.setNull(5, java.sql.Types.TIMESTAMP);
            }

            stmt.executeUpdate();

            try (ResultSet rs = stmt.getGeneratedKeys()) {
                if (rs.next()) {
                    todo.setId(rs.getInt(1));
                }
            }

            logger.info("Created todo with id: {}", todo.getId());
            return todo;
        } catch (SQLException e) {
            logger.error("Failed to create todo", e);
            throw new RuntimeException("Failed to create todo", e);
        }
    }

    /**
     * Updates an existing Todo item in the database.
     *
     * @param todo the Todo item to update
     * @return the updated Todo item, or null if not found
     */
    public Todo updateTodo(Todo todo) {
        String query = 
            "UPDATE todos "
            + "SET title = ?, description = ?, completed = ?, completed_at = ? "
            + "WHERE id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setString(1, todo.getTitle());
            stmt.setString(2, todo.getDescription());
            stmt.setBoolean(3, todo.isCompleted());

            if (todo.isCompleted()) {
                stmt.setTimestamp(4, new java.sql.Timestamp(todo.getCompletedAt()));
            } else {
                stmt.setNull(4, java.sql.Types.TIMESTAMP);
            }
            stmt.setInt(5, todo.getId());

            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected == 0) {
                return null;
            }
            return todo;
        } catch (SQLException e) {
            logger.error("Failed to update todo", e);
            throw new RuntimeException("Failed to update todo", e);
        }
    }

    /**
     * Deletes a Todo item from the database.
     *
     * @param id the ID of the Todo item to delete
     * @return true if the todo was deleted, false if not found
     */
    public boolean deleteTodo(String id) {
        String query = "DELETE FROM todos WHERE id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, Integer.parseInt(id));
            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                logger.info("Deleted todo with id: {}", id);
                return true;
            }
            return false;
        } catch (SQLException e) {
            logger.error("Failed to delete todo", e);
            throw new RuntimeException("Failed to delete todo", e);
        }
    }

    /**
     * Closes the database connection.
     */
    public void close() {
        if (connection != null) {
            try {
                connection.close();
            } catch (SQLException e) {
                logger.error("Failed to close database connection", e);
            }
        }
    }
} 