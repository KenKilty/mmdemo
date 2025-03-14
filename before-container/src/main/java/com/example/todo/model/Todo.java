package com.example.todo.model;

import java.io.Serializable;
import java.util.Date;

/**
 * Represents a Todo item in the application.
 * Contains basic information about a task including its ID, title, description,
 * completion status, and creation timestamp.
 */
public class Todo implements Serializable {
    private Long id;
    private String title;
    private String description;
    private boolean completed;
    private Date createdAt;
    private Date completedAt;

    public Todo() {
        this.createdAt = new Date();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isCompleted() {
        return completed;
    }

    public void setCompleted(boolean completed) {
        this.completed = completed;
        if (completed) {
            this.completedAt = new Date();
        } else {
            this.completedAt = null;
        }
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public Date getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(Date completedAt) {
        this.completedAt = completedAt;
    }

    /**
     * Compares this Todo with the specified object for equality.
     * Two todos are considered equal if they have the same ID.
     *
     * @param obj the object to compare with
     * @return true if the objects are equal, false otherwise
     */
    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null || getClass() != obj.getClass()) {
            return false;
        }
        Todo other = (Todo) obj;
        return id != null && id.equals(other.id);
    }
}