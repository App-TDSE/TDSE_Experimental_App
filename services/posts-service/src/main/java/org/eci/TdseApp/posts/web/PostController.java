package org.eci.TdseApp.posts.web;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.eci.TdseApp.posts.model.Post;
import org.eci.TdseApp.posts.service.PostService;
import org.eci.TdseApp.posts.web.dto.CreatePostRequest;
import org.eci.TdseApp.posts.web.dto.PostResponse;
import org.eci.TdseApp.posts.web.dto.UpdatePostRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
@Tag(name = "Posts", description = "Create, read, update and delete posts")
public class PostController {
    private final PostService postService;

    @GetMapping
    @Operation(summary = "List all posts, newest first", description = "Public endpoint.")
    @ApiResponse(responseCode = "200", description = "List of posts returned")
    public List<PostResponse> getAllPosts() {
        return postService.getAllPosts().stream().map(PostResponse::from).toList();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a single post by id", description = "Public endpoint.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Post found"),
            @ApiResponse(responseCode = "404", description = "Post not found")
    })
    public PostResponse getPost(@PathVariable("id") UUID id) {
        return PostResponse.from(postService.getPostById(id));
    }

    @PostMapping
    @Operation(
            summary = "Create a new post",
            description = "Requires a valid JWT. Author is taken from the token, not the body.",
            security = @SecurityRequirement(name = "bearer-jwt")
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Post created"),
            @ApiResponse(responseCode = "400", description = "Validation failed (blank content or > 140 chars)"),
            @ApiResponse(responseCode = "401", description = "Missing or invalid token")
    })
    @PreAuthorize("hasAuthority('SCOPE_write:posts')")
    public ResponseEntity<PostResponse> createPost(@Valid @RequestBody CreatePostRequest request, @AuthenticationPrincipal Jwt jwt) {
        String username = jwt.getClaimAsString("name");
        if (username == null) {
            username = jwt.getClaimAsString("https://tdseapp.api/name");
        }
        if (username == null) {
            username = "User";
        }

        Post created = postService.createPost(jwt.getSubject(), username, request.content());
        return ResponseEntity.status(HttpStatus.CREATED).body(PostResponse.from(created));
    }

    @PutMapping("/{id}")
    @Operation(
            summary = "Update your own post",
            description = "Only the author of the post may update it.",
            security = @SecurityRequirement(name = "bearer-jwt")
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Post updated"),
            @ApiResponse(responseCode = "400", description = "Validation failed"),
            @ApiResponse(responseCode = "401", description = "Missing or invalid token"),
            @ApiResponse(responseCode = "403", description = "Not the owner of the post"),
            @ApiResponse(responseCode = "404", description = "Post not found")
    })
    @PreAuthorize("hasAuthority('SCOPE_write:posts')")
    public PostResponse updatePost(@PathVariable("id") UUID id, @Valid @RequestBody UpdatePostRequest request, @AuthenticationPrincipal Jwt jwt) {
        Post updated = postService.updatePost(id, jwt.getSubject(), request.content());
        return PostResponse.from(updated);
    }

    @DeleteMapping("/{id}")
    @Operation(
            summary = "Delete your own post",
            description = "Only the author of the post may delete it.",
            security = @SecurityRequirement(name = "bearer-jwt")
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Post deleted"),
            @ApiResponse(responseCode = "401", description = "Missing or invalid token"),
            @ApiResponse(responseCode = "403", description = "Not the owner of the post"),
            @ApiResponse(responseCode = "404", description = "Post not found")
    })
    @PreAuthorize("hasAuthority('SCOPE_write:posts')")
    public ResponseEntity<Void> deletePost(@PathVariable("id") UUID id, @AuthenticationPrincipal Jwt jwt) {
        postService.deletePost(id, jwt.getSubject());
        return ResponseEntity.noContent().build();
    }
}
