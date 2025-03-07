package com.example.todo.model;

// Java core imports
import java.io.Serializable;

/**
 * Represents a Todo item with basic task management properties.
 * Implements Serializable for JSON serialization/deserialization.
 */
public class Todo implements Serializable {
    private Integer id;
    private String title;
    private String description;
    private boolean completed;
    private long createdAt;
    private Long completedAt;

    /**
     * Creates a new Todo with the current timestamp.
     */
    public Todo() {
        this.createdAt = System.currentTimeMillis();
    }

    /**
     * Gets the Todo's unique identifier.
     *
     * @return The Todo's ID
     */
    public Integer getId() {
        return id;
    }

    /**
     * Sets the Todo's unique identifier.
     *
     * @param id The ID to set
     */
    public void setId(Integer id) {
        this.id = id;
    }

    /**
     * Gets the Todo's title.
     *
     * @return The title
     */
    public String getTitle() {
        return title;
    }

    /**
     * Sets the Todo's title.
     *
     * @param title The title to set
     */
    public void setTitle(String title) {
        this.title = title;
    }

    /**
     * Gets the Todo's description.
     *
     * @return The description
     */
    public String getDescription() {
        return description;
    }

    /**
     * Sets the Todo's description.
     *
     * @param description The description to set
     */
    public void setDescription(String description) {
        this.description = description;
    }

    /**
     * Checks if the Todo is completed.
     *
     * @return true if completed, false otherwise
     */
    public boolean isCompleted() {
        return completed;
    }

    /**
     * Sets the Todo's completion status and updates the completedAt timestamp.
     *
     * @param completed The completion status to set
     */
    public void setCompleted(boolean completed) {
        this.completed = completed;
        if (completed && completedAt == null) {
            this.completedAt = System.currentTimeMillis();
        } else {
            this.completedAt = null;
        }
    }

    /**
     * Gets the Todo's creation timestamp.
     *
     * @return The creation timestamp in milliseconds
     */
    public long getCreatedAt() {
        return createdAt;
    }

    /**
     * Sets the Todo's creation timestamp.
     *
     * @param createdAt The creation timestamp to set
     */
    public void setCreatedAt(long createdAt) {
        this.createdAt = createdAt;
    }

    /**
     * Gets the Todo's completion timestamp.
     *
     * @return The completion timestamp in milliseconds, or null if not completed
     */
    public Long getCompletedAt() {
        return completedAt;
    }

    /**
     * Sets the Todo's completion timestamp.
     *
     * @param completedAt The completion timestamp to set
     */
    public void setCompletedAt(Long completedAt) {
        this.completedAt = completedAt;
    }
} 