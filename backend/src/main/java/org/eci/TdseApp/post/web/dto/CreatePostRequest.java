package org.eci.TdseApp.post.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Payload to create a new post")
public record CreatePostRequest(
        @Schema(description = "Text of the post, 1 to 140 characters", example = "Hello world")
        @NotBlank(message = "content must not be blank")
        @Size(max = 140, message = "content must be at most 140 characters")
        String content
) {}
