package org.eci.TdseApp.posts.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Post {
    private UUID postId;
    private String username;
    private String content;
    private Instant createdAt;
    private String userId;
}
