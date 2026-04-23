package edu.co.escuela.ing.MicroserviciosLambda.model;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "posts")
@Schema(description = "Represents a post in the public stream")
public class Post {

    @Id
    @Schema(description = "Unique identifier of the post (UUID)", example = "3fa85f64-5717-4562-b3fc-2c963f66afa6")
    private String id;

    @Column(nullable = false, length = 140)
    @Schema(description = "Content of the post (max 140 characters)", example = "Hello Twitter!", maxLength = 140)
    private String content;

    @Column(name = "author_id", nullable = false)
    @Schema(description = "Auth0 subject ID of the author", example = "google-oauth2|123456789")
    private String authorId;

    @Column(nullable = false)
    @Schema(description = "Timestamp when the post was created")
    private LocalDateTime timestamp;

    public Post() {}

    public Post(String id, String content, String authorId, LocalDateTime timestamp) {
        this.id = id;
        this.content = content;
        this.authorId = authorId;
        this.timestamp = timestamp;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getAuthorId() { return authorId; }
    public void setAuthorId(String authorId) { this.authorId = authorId; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
}
