package org.eci.TdseApp.posts.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreatePostRequest(
        @NotBlank(message = "Content cannot be blank")
        @Size(min = 1, max = 140, message = "Content must be between 1 and 140 characters")
        String content
) {}
