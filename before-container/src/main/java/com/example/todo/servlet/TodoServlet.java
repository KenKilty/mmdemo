package com.example.todo.servlet;

import java.io.IOException;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
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
        
        if (pathInfo == null || pathInfo.equals("/")) {
            // Get all todos
            List<Todo> todos = cache.getCachedTodos();
            if (todos == null) {
                todos = storage.loadTodos();
                cache.cacheTodos(todos);
            }
            sendJsonResponse(resp, todos);
        } else {
            // Get single todo
            Long id = Long.parseLong(pathInfo.substring(1));
            Todo todo = cache.getCachedTodo(id);
            if (todo == null) {
                List<Todo> todos = storage.loadTodos();
                todo = todos.stream()
                        .filter(t -> t.getId().equals(id))
                        .findFirst()
                        .orElse(null);
                if (todo != null) {
                    cache.cacheTodo(todo);
                }
            }
            if (todo != null) {
                sendJsonResponse(resp, todo);
            } else {
                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            }
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
        Todo todo = objectMapper.readValue(req.getReader(), Todo.class);
        todo = storage.addTodo(todo);
        cache.invalidateCache();
        cache.cacheTodo(todo);
        sendJsonResponse(resp, todo);
        resp.setStatus(HttpServletResponse.SC_CREATED);
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
        if (pathInfo == null || pathInfo.equals("/")) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        Long id = Long.parseLong(pathInfo.substring(1));
        Todo updatedTodo = objectMapper.readValue(req.getReader(), Todo.class);
        
        // Get the existing todo
        List<Todo> todos = storage.loadTodos();
        Todo existingTodo = todos.stream()
                .filter(t -> t.getId().equals(id))
                .findFirst()
                .orElse(null);
                
        if (existingTodo == null) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        // Update only the provided fields
        if (updatedTodo.getTitle() != null) {
            existingTodo.setTitle(updatedTodo.getTitle());
        }
        if (updatedTodo.getDescription() != null) {
            existingTodo.setDescription(updatedTodo.getDescription());
        }
        existingTodo.setCompleted(updatedTodo.isCompleted());
        
        storage.updateTodo(existingTodo);
        cache.invalidateCache();
        cache.cacheTodo(existingTodo);
        sendJsonResponse(resp, existingTodo);
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
        if (pathInfo == null || pathInfo.equals("/")) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        Long id = Long.parseLong(pathInfo.substring(1));
        storage.deleteTodo(id);
        cache.invalidateCache();
        cache.removeTodoFromCache(id);
        resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
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
    }
} 