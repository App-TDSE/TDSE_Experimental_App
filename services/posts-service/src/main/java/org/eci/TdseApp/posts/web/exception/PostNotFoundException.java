package org.eci.TdseApp.posts.web.exception;

import java.util.UUID;

public class PostNotFoundException extends RuntimeException {
    public PostNotFoundException(UUID id) {
        super("Post not found: " + id);
    }
}
