package org.eci.TdseApp.posts.web.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.eci.TdseApp.posts.model.Post;

import java.time.Instant;
import java.util.UUID;

public record PostResponse(
        @JsonProperty("id")
        UUID id,
        @JsonProperty("username")
        String username,
        @JsonProperty("content")
        String content,
        @JsonProperty("createdAt")
        Instant createdAt,
        @JsonProperty("userId")
        String userId
) {
    public static PostResponse from(Post post) {
        return new PostResponse(
                post.getPostId(),
                post.getUsername(),
                post.getContent(),
                post.getCreatedAt(),
                post.getUserId()
        );
    }
}
