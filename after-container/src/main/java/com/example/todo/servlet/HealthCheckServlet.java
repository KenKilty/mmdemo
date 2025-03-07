package com.example.todo.servlet;

import com.example.todo.service.TodoStorage;
import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Servlet for handling health check requests.
 * Returns 200 OK if the application is healthy, 503 Service Unavailable otherwise.
 */
public class HealthCheckServlet extends HttpServlet {
  private static final Logger logger = LoggerFactory.getLogger(HealthCheckServlet.class);
  private TodoStorage storage;

  @Override
  public void init(ServletConfig config) throws ServletException {
    super.init(config);
    ServletContext context = config.getServletContext();
    storage = (TodoStorage) context.getAttribute("todoStorage");
    if (storage == null) {
      throw new ServletException("TodoStorage not found in ServletContext");
    }
    logger.info("HealthCheckServlet initialized with storage");
  }

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response) 
      throws IOException {
    try {
      // Check database connectivity
      storage.checkHealth();
      
      // If we get here, the application is healthy
      response.setStatus(HttpServletResponse.SC_OK);
      response.setContentType("application/json");
      response.getWriter().write("{\"status\":\"UP\"}");
    } catch (Exception e) {
      // If there's any error, the application is not healthy
      response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
      response.setContentType("application/json");
      response.getWriter().write("{\"status\":\"DOWN\",\"error\":\"" + e.getMessage() + "\"}");
    }
  }
} 