package org.eci.TdseApp.post.web.exception;

/**
 * Thrown when an authenticated user attempts to modify a post they do not
 * own. Mapped to HTTP 403 by the global exception handler.
 */
public class ForbiddenActionException extends RuntimeException {
    public ForbiddenActionException(String message) {
        super(message);
    }
}
