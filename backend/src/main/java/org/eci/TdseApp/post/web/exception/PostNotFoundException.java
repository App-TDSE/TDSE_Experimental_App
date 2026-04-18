package org.eci.TdseApp.post.web.exception;

import java.util.UUID;

public class PostNotFoundException extends RuntimeException {
    public PostNotFoundException(UUID postId) {
        super("Post not found: " + postId);
    }
}
