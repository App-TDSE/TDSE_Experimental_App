package edu.co.escuela.ing.MicroserviciosLambda.model;

import java.time.LocalDateTime;

public class Post {
    private String id;
    private String content;
    private String authorId;
    private LocalDateTime timestamp;

    public Post() {}

    public Post(String id, String content, String authorId, LocalDateTime timestamp) {
        this.id = id;
        this.content = content;
        this.authorId = authorId;
        this.timestamp = timestamp;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getAuthorId() {
        return authorId;
    }

    public void setAuthorId(String authorId) {
        this.authorId = authorId;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
}
