package org.eci.TdseApp.post.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import org.eci.TdseApp.post.model.Post;

import java.time.Instant;
import java.util.UUID;

@Schema(description = "Public view of a post")
public record PostResponse(
        @Schema(description = "Unique post identifier")
        UUID postId,

        @Schema(description = "Auth0 subject of the author")
        String userId,

        @Schema(description = "Display name of the author at the time the post was created")
        String username,

        @Schema(description = "Post content, up to 140 characters")
        String content,

        @Schema(description = "Server-side creation timestamp in UTC")
        Instant createdAt
) {
    public static PostResponse from(Post post) {
        return new PostResponse(
                post.getPostId(),
                post.getUserId(),
                post.getUsername(),
                post.getContent(),
                post.getCreatedAt()
        );
    }
}
