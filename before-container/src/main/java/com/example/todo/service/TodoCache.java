package com.example.todo.service;

import java.util.List;
import java.util.Properties;

import com.example.todo.model.Todo;
import net.sf.ehcache.Cache;
import net.sf.ehcache.CacheManager;
import net.sf.ehcache.Element;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Manages caching of Todo items using EhCache.
 * Provides caching operations for both individual todos and the complete list.
 */
public class TodoCache {
    private static final Logger logger = LoggerFactory.getLogger(TodoCache.class);
    private final Cache cache;
    private static final String ALL_TODOS_KEY = "all_todos";

    /**
     * Initializes the cache using configuration from properties file and ehcache.xml.
     *
     * @throws RuntimeException if cache initialization fails
     */
    public TodoCache() {
        try {
            Properties props = new Properties();
            props.load(getClass().getClassLoader().getResourceAsStream("config.properties"));
            String cacheName = props.getProperty("cache.name");
            
            CacheManager cacheManager = CacheManager.create(
                getClass().getClassLoader().getResourceAsStream("ehcache.xml"));
            this.cache = cacheManager.getCache(cacheName);
            
            if (this.cache == null) {
                throw new RuntimeException(
                    "Cache '" + cacheName + "' not found in configuration");
            }
        } catch (Exception e) {
            logger.error("Failed to initialize cache", e);
            throw new RuntimeException("Cache initialization failed", e);
        }
    }

    /**
     * Caches the complete list of todos.
     *
     * @param todos List of todos to cache
     */
    public void cacheTodos(List<Todo> todos) {
        cache.put(new Element(ALL_TODOS_KEY, todos));
        logger.info("Cached {} todos", todos.size());
    }

    /**
     * Retrieves the cached list of all todos.
     *
     * @return List of cached todos, or null if not found in cache
     */
    @SuppressWarnings("unchecked")
    public List<Todo> getCachedTodos() {
        Element element = cache.get(ALL_TODOS_KEY);
        if (element != null) {
            logger.info("Cache hit for todos list");
            return (List<Todo>) element.getObjectValue();
        }
        logger.info("Cache miss for todos list");
        return null;
    }

    /**
     * Invalidates the cache by removing all todos.
     * This method also clears any individual todo items.
     */
    public void invalidateCache() {
        cache.removeAll();
        logger.info("Cache fully invalidated");
    }

    /**
     * Caches a single todo item.
     *
     * @param todo The todo to cache
     */
    public void cacheTodo(Todo todo) {
        cache.put(new Element(todo.getId(), todo));
        logger.info("Cached todo with id: {}", todo.getId());
    }

    /**
     * Retrieves a cached todo by its ID.
     *
     * @param id The ID of the todo to retrieve
     * @return The cached todo, or null if not found in cache
     */
    public Todo getCachedTodo(Long id) {
        Element element = cache.get(id);
        if (element != null) {
            logger.info("Cache hit for todo id: {}", id);
            return (Todo) element.getObjectValue();
        }
        logger.info("Cache miss for todo id: {}", id);
        return null;
    }

    /**
     * Removes a todo from the cache.
     *
     * @param id The ID of the todo to remove from cache
     */
    public void removeTodoFromCache(Long id) {
        cache.remove(id);
        logger.info("Removed todo with id {} from cache", id);
    }
}