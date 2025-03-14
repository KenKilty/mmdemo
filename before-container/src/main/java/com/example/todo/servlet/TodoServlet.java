package com.example.todo.servlet;

import java.io.IOException;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.todo.model.Todo;
import com.example.todo.service.TodoCache;
import com.example.todo.service.TodoStorage;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Servlet handling HTTP requests for Todo operations.
 * Provides CRUD operations for Todo items with caching support.
 */
public class TodoServlet extends HttpServlet {
    private static final Logger logger = LoggerFactory.getLogger(TodoServlet.class);
    private final TodoStorage storage;
    private final TodoCache cache;
    private final ObjectMapper objectMapper;

    public TodoServlet() {
        this.storage = new TodoStorage();
        this.cache = new TodoCache();
        this.objectMapper = new ObjectMapper();
        logger.info("TodoServlet initialized");
    }

    /**
     * Handles GET requests for todos.
     * Returns either all todos or a single todo by ID.
     *
     * @param req The HTTP request
     * @param resp The HTTP response
     * @throws ServletException If a servlet-specific error occurs
     * @throws IOException If an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        logger.debug("GET request received with path: {}", pathInfo);
        
        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                // Get all todos
                logger.debug("Retrieving all todos");
                List<Todo> todos = cache.getCachedTodos();
                if (todos == null) {
                    logger.debug("Cache miss for todos list, loading from storage");
                    todos = storage.loadTodos();
                    cache.cacheTodos(todos);
                    logger.debug("Cached {} todos", todos.size());
                } else {
                    logger.debug("Retrieved {} todos from cache", todos.size());
                }
                sendJsonResponse(resp, todos);
            } else {
                // Get single todo
                try {
                    Long id = Long.parseLong(pathInfo.substring(1));
                    logger.debug("Retrieving todo with id: {}", id);
                    
                    Todo todo = cache.getCachedTodo(id);
                    if (todo == null) {
                        logger.debug("Cache miss for todo id: {}", id);
                        // First check if the todos list is cached to avoid loading from storage
                        List<Todo> cachedTodos = cache.getCachedTodos();
                        if (cachedTodos != null) {
                            todo = cachedTodos.stream()
                                    .filter(t -> t.getId().equals(id))
                                    .findFirst()
                                    .orElse(null);
                            
                            if (todo != null) {
                                logger.debug("Found todo in cached list, caching individual todo: {}", todo.getId());
                                cache.cacheTodo(todo);
                            }
                        }
                        
                        // If not found in cached list, load from storage
                        if (todo == null) {
                            List<Todo> todos = storage.loadTodos();
                            todo = todos.stream()
                                    .filter(t -> t.getId().equals(id))
                                    .findFirst()
                                    .orElse(null);
                            if (todo != null) {
                                logger.debug("Found todo in storage, caching: {}", todo.getId());
                                cache.cacheTodo(todo);
                            } else {
                                logger.warn("Todo with id: {} not found", id);
                            }
                        }
                    } else {
                        logger.debug("Retrieved todo from cache: {}", todo.getId());
                    }
                    
                    if (todo != null) {
                        sendJsonResponse(resp, todo);
                    } else {
                        resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    }
                } catch (NumberFormatException e) {
                    logger.error("Invalid todo ID format: {}", pathInfo.substring(1));
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                }
            }
        } catch (Exception e) {
            logger.error("Error retrieving todos", e);
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Handles POST requests to create new todos.
     *
     * @param req The HTTP request containing the todo data
     * @param resp The HTTP response
     * @throws ServletException If a servlet-specific error occurs
     * @throws IOException If an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        logger.debug("POST request received to create new todo");
        try {
            Todo todo = objectMapper.readValue(req.getReader(), Todo.class);
            logger.debug("Parsed todo from request: {}", todo.getTitle());
            
            todo = storage.addTodo(todo);
            logger.info("Created new todo with id: {}", todo.getId());
            
            cache.invalidateCache();
            logger.debug("Cache invalidated after todo creation");
            
            cache.cacheTodo(todo);
            logger.debug("New todo cached: {}", todo.getId());
            
            sendJsonResponse(resp, todo);
            resp.setStatus(HttpServletResponse.SC_CREATED);
        } catch (Exception e) {
            logger.error("Error creating todo", e);
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        }
    }

    /**
     * Handles PUT requests to update existing todos.
     *
     * @param req The HTTP request containing the updated todo data
     * @param resp The HTTP response
     * @throws ServletException If a servlet-specific error occurs
     * @throws IOException If an I/O error occurs
     */
    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        logger.debug("PUT request received with path: {}", pathInfo);
        
        if (pathInfo == null || pathInfo.equals("/")) {
            logger.warn("PUT request missing ID parameter");
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            Long id = Long.parseLong(pathInfo.substring(1));
            logger.debug("Updating todo with id: {}", id);
            
            Todo updatedTodo = objectMapper.readValue(req.getReader(), Todo.class);
            logger.debug("Parsed updated todo from request: {}", updatedTodo.getTitle());
            
            // Get the existing todo
            List<Todo> todos = storage.loadTodos();
            Todo existingTodo = todos.stream()
                    .filter(t -> t.getId().equals(id))
                    .findFirst()
                    .orElse(null);
                    
            if (existingTodo == null) {
                logger.warn("Todo with id: {} not found for update", id);
                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            logger.debug("Found existing todo: {}", existingTodo.getTitle());
            
            // Update only the provided fields
            if (updatedTodo.getTitle() != null) {
                existingTodo.setTitle(updatedTodo.getTitle());
            }
            if (updatedTodo.getDescription() != null) {
                existingTodo.setDescription(updatedTodo.getDescription());
            }
            existingTodo.setCompleted(updatedTodo.isCompleted());
            
            storage.updateTodo(existingTodo);
            logger.info("Updated todo with id: {}", existingTodo.getId());
            
            cache.invalidateCache();
            logger.debug("Cache invalidated after todo update");
            
            cache.cacheTodo(existingTodo);
            logger.debug("Updated todo cached: {}", existingTodo.getId());
            
            sendJsonResponse(resp, existingTodo);
        } catch (NumberFormatException e) {
            logger.error("Invalid todo ID format", e);
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        } catch (Exception e) {
            logger.error("Error updating todo", e);
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Handles DELETE requests to remove todos.
     *
     * @param req The HTTP request specifying the todo to delete
     * @param resp The HTTP response
     * @throws ServletException If a servlet-specific error occurs
     * @throws IOException If an I/O error occurs
     */
    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        logger.debug("DELETE request received with path: {}", pathInfo);
        
        if (pathInfo == null || pathInfo.equals("/")) {
            logger.warn("DELETE request missing ID parameter");
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            Long id = Long.parseLong(pathInfo.substring(1));
            logger.debug("Deleting todo with id: {}", id);
            
            storage.deleteTodo(id);
            logger.info("Deleted todo with id: {}", id);
            
            cache.invalidateCache();
            logger.debug("Cache invalidated after todo deletion");
            
            cache.removeTodoFromCache(id);
            logger.debug("Removed todo from cache: {}", id);
            
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (NumberFormatException e) {
            logger.error("Invalid todo ID format", e);
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        } catch (Exception e) {
            logger.error("Error deleting todo", e);
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Sends a JSON response to the client.
     *
     * @param resp The HTTP response
     * @param obj The object to serialize as JSON
     * @throws IOException If an I/O error occurs
     */
    private void sendJsonResponse(HttpServletResponse resp, Object obj) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        objectMapper.writeValue(resp.getOutputStream(), obj);
        logger.debug("JSON response sent successfully");
    }
}