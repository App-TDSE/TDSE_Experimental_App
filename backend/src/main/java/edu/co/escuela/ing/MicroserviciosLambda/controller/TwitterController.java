package edu.co.escuela.ing.MicroserviciosLambda.controller;

import edu.co.escuela.ing.MicroserviciosLambda.model.Post;
import edu.co.escuela.ing.MicroserviciosLambda.model.PostRequest;
import edu.co.escuela.ing.MicroserviciosLambda.model.User;
import edu.co.escuela.ing.MicroserviciosLambda.service.TwitterService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*") // Para desarrollo
public class TwitterController {

    private final TwitterService twitterService;

    public TwitterController(TwitterService twitterService) {
        this.twitterService = twitterService;
    }

    @GetMapping("/stream")
    public List<Post> getStream() {
        return twitterService.getAllPosts();
    }

    @PostMapping("/posts")
    public ResponseEntity<?> createPost(@RequestBody PostRequest request, @AuthenticationPrincipal Jwt jwt) {
        try {
            // Extract user from JWT. In Auth0, subject is usually the user ID.
            String authorId = jwt != null ? jwt.getSubject() : "unknown"; 
            Post post = twitterService.createPost(request.getContent(), authorId);
            return ResponseEntity.ok(post);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/me")
    public ResponseEntity<?> getMe(@AuthenticationPrincipal Jwt jwt) {
        if (jwt != null) {
            return ResponseEntity.ok(jwt.getClaims());
        }
        return ResponseEntity.status(401).build();
    }
}
