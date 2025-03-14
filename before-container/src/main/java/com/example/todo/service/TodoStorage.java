package com.example.todo.service;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.concurrent.atomic.AtomicLong;

import com.example.todo.model.Todo;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Handles persistence of Todo items to the file system.
 * Manages CRUD operations for todos using file-based storage.
 */
public class TodoStorage {
    private static final Logger logger = LoggerFactory.getLogger(TodoStorage.class);
    private final String storagePath;
    private final ObjectMapper objectMapper;
    private static AtomicLong idGenerator = new AtomicLong(1);
    // This is potentially problematic as it doesn't account for existing IDs in the storage

    /**
     * Initializes the storage system using configuration from properties file.
     * Creates storage directory if it doesn't exist.
     *
     * @throws RuntimeException if initialization fails
     */
    public TodoStorage() {
        Properties props = new Properties();
        try {
            props.load(getClass().getClassLoader().getResourceAsStream("config.properties"));
            String relativePath = props.getProperty("storage.path");
            
            // Resolve the path relative to the user.dir (project root)
            this.storagePath = new File(System.getProperty("user.dir"), relativePath).getAbsolutePath();
            this.objectMapper = new ObjectMapper();
            
            // Create storage directory if it doesn't exist
            File storageDir = new File(storagePath).getParentFile();
            if (!storageDir.exists()) {
                storageDir.mkdirs();
            }
            
            logger.info("Using storage path: {}", 
                storagePath);
                
            // Initialize ID generator from existing data
            initializeIdGenerator();
        } catch (IOException e) {
            logger.error("Failed to load configuration", e);
            throw new RuntimeException("Failed to initialize storage", e);
        }
    }
    
    /**
     * Initializes the ID generator based on existing data to avoid ID conflicts.
     */
    private void initializeIdGenerator() {
        List<Todo> existingTodos = loadTodos();
        if (!existingTodos.isEmpty()) {
            long maxId = existingTodos.stream()
                .mapToLong(Todo::getId)
                .max()
                .orElse(0);
            idGenerator.set(maxId + 1);
            logger.info("ID generator initialized to {}", idGenerator.get());
        }
    }

    /**
     * Loads all todos from storage.
     *
     * @return List of todos, empty list if no todos exist or if loading fails
     */
    public List<Todo> loadTodos() {
        File file = new File(storagePath);
        if (!file.exists()) {
            return new ArrayList<>();
        }

        try {
            return objectMapper.readValue(file, new TypeReference<List<Todo>>() {});
        } catch (IOException e) {
            logger.error("Failed to load todos from file", e);
            return new ArrayList<>();
        }
    }

    /**
     * Saves the complete list of todos to persistent storage.
     * This method writes the entire list of todos to a JSON file.
     *
     * @param todos the list of todos to save
     * @throws IOException if there is an error writing to the storage file
     */
    public void saveTodos(List<Todo> todos) throws IOException {
        objectMapper.writeValue(new File(storagePath), todos);
    }

    /**
     * Adds a new todo to storage.
     *
     * @param todo The todo to add (without ID)
     * @return The same todo with generated ID
     */
    public Todo addTodo(Todo todo) {
        List<Todo> todos = loadTodos();
        todo.setId(idGenerator.getAndIncrement());
        todos.add(todo);
        try {
            saveTodos(todos);
        } catch (IOException e) {
            logger.error("Failed to add todo", e);
            throw new RuntimeException("Failed to add todo", e);
        }
        return todo;
    }

    /**
     * Updates an existing todo in storage.
     *
     * @param todo The todo with updated fields
     */
    public void updateTodo(Todo todo) {
        List<Todo> todos = loadTodos();
        for (int i = 0; i < todos.size(); i++) {
            if (todos.get(i).getId().equals(todo.getId())) {
                todos.set(i, todo);
                break;
            }
        }
        try {
            saveTodos(todos);
        } catch (IOException e) {
            logger.error("Failed to update todo", e);
            throw new RuntimeException("Failed to update todo", e);
        }
    }

    /**
     * Deletes a todo from storage.
     *
     * @param id The ID of the todo to delete
     */
    public void deleteTodo(Long id) {
        List<Todo> todos = loadTodos();
        todos.removeIf(todo -> todo.getId().equals(id));
        try {
            saveTodos(todos);
        } catch (IOException e) {
            logger.error("Failed to delete todo", e);
            throw new RuntimeException("Failed to delete todo", e);
        }
    }
}