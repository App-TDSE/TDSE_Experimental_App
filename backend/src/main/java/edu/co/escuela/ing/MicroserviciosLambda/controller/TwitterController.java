package edu.co.escuela.ing.MicroserviciosLambda.controller;

import edu.co.escuela.ing.MicroserviciosLambda.model.Post;
import edu.co.escuela.ing.MicroserviciosLambda.model.PostRequest;
import edu.co.escuela.ing.MicroserviciosLambda.service.TwitterService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
@Tag(name = "Mini-Twitter API", description = "Endpoints for the Mini-Twitter application")
public class TwitterController {

    private final TwitterService twitterService;

    public TwitterController(TwitterService twitterService) {
        this.twitterService = twitterService;
    }

    @Operation(
        summary = "Get public stream",
        description = "Returns all posts in the global public feed ordered by date descending. No authentication required."
    )
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "List of posts retrieved successfully")
    })
    @GetMapping("/stream")
    public List<Post> getStream() {
        return twitterService.getAllPosts();
    }

    @Operation(
        summary = "Create a post",
        description = "Creates a new post in the global stream. Maximum 140 characters. Requires a valid Auth0 JWT Bearer token."
    )
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Post created successfully"),
        @ApiResponse(responseCode = "400", description = "Content is empty or exceeds 140 characters"),
        @ApiResponse(responseCode = "401", description = "Unauthorized — valid JWT token required")
    })
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/posts")
    public ResponseEntity<?> createPost(@RequestBody PostRequest request, @AuthenticationPrincipal Jwt jwt) {
        try {
            String authorId = jwt != null ? jwt.getSubject() : "unknown";
            Post post = twitterService.createPost(request.getContent(), authorId);
            return ResponseEntity.ok(post);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @Operation(
        summary = "Get current user info",
        description = "Returns the JWT claims of the currently authenticated user (sub, email, name, etc.). Requires a valid Auth0 JWT Bearer token."
    )
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "User claims returned successfully"),
        @ApiResponse(responseCode = "401", description = "Unauthorized — valid JWT token required")
    })
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/me")
    public ResponseEntity<?> getMe(@AuthenticationPrincipal Jwt jwt) {
        if (jwt != null) {
            return ResponseEntity.ok(jwt.getClaims());
        }
        return ResponseEntity.status(401).build();
    }
}
