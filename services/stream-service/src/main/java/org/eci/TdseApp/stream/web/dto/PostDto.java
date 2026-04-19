package org.eci.TdseApp.stream.web.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.UUID;

public record PostDto(
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
) {}
