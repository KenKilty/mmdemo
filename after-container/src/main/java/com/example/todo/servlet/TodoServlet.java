package com.example.todo.servlet;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.example.todo.model.Todo;
import com.example.todo.service.TodoStorage;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Servlet for handling Todo CRUD operations.
 */
public class TodoServlet extends HttpServlet {
  private static final Logger logger = LoggerFactory.getLogger(TodoServlet.class);
  private TodoStorage storage;
  private final ObjectMapper objectMapper = new ObjectMapper();

  @Override
  public void init(ServletConfig config) throws ServletException {
    super.init(config);
    ServletContext context = config.getServletContext();
    storage = (TodoStorage) context.getAttribute("todoStorage");
    if (storage == null) {
      throw new ServletException("TodoStorage not found in ServletContext");
    }
    logger.info("TodoServlet initialized with storage");
  }

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response)
      throws IOException {
    List<Todo> todos = storage.getAllTodos();
    response.setContentType("application/json");
    objectMapper.writeValue(response.getWriter(), todos);
  }

  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response)
      throws IOException {
    Todo todo = objectMapper.readValue(request.getReader(), Todo.class);
    Todo createdTodo = storage.createTodo(todo);
    response.setContentType("application/json");
    response.setStatus(HttpServletResponse.SC_CREATED);
    objectMapper.writeValue(response.getWriter(), createdTodo);
  }

  @Override
  protected void doPut(HttpServletRequest request, HttpServletResponse response)
      throws IOException {
    Todo todo = objectMapper.readValue(request.getReader(), Todo.class);
    Todo updatedTodo = storage.updateTodo(todo);
    if (updatedTodo == null) {
      response.setStatus(HttpServletResponse.SC_NOT_FOUND);
      return;
    }
    response.setContentType("application/json");
    objectMapper.writeValue(response.getWriter(), updatedTodo);
  }

  @Override
  protected void doDelete(HttpServletRequest request, HttpServletResponse response)
      throws IOException {
    String pathInfo = request.getPathInfo();
    if (pathInfo == null || pathInfo.equals("/")) {
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      return;
    }
    String todoId = pathInfo.substring(1);
    boolean deleted = storage.deleteTodo(todoId);
    if (!deleted) {
      response.setStatus(HttpServletResponse.SC_NOT_FOUND);
      return;
    }
    response.setStatus(HttpServletResponse.SC_NO_CONTENT);
  }
} 