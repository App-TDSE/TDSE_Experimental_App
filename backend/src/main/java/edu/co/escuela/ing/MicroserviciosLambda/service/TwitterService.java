package edu.co.escuela.ing.MicroserviciosLambda.service;

import edu.co.escuela.ing.MicroserviciosLambda.model.Post;
import edu.co.escuela.ing.MicroserviciosLambda.model.User;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class TwitterService {

    private final List<Post> posts = new CopyOnWriteArrayList<>();
    private final List<User> users = new CopyOnWriteArrayList<>();

    public TwitterService() {
        // Mock data
        users.add(new User("1", "alice", "alice@example.com"));
        users.add(new User("2", "bob", "bob@example.com"));
        posts.add(new Post(UUID.randomUUID().toString(), "Hello world!", "1", LocalDateTime.now().minusHours(1)));
        posts.add(new Post(UUID.randomUUID().toString(), "This is my first post", "2", LocalDateTime.now()));
    }

    public List<Post> getAllPosts() {
        List<Post> sortedPosts = new ArrayList<>(posts);
        sortedPosts.sort((p1, p2) -> p2.getTimestamp().compareTo(p1.getTimestamp()));
        return sortedPosts;
    }

    public Post createPost(String content, String authorId) {
        if (content == null || content.trim().isEmpty()) {
            throw new IllegalArgumentException("Post content cannot be empty");
        }
        if (content.length() > 140) {
            throw new IllegalArgumentException("Post exceeds 140 characters limit");
        }
        
        Post post = new Post(UUID.randomUUID().toString(), content, authorId, LocalDateTime.now());
        posts.add(post);
        return post;
    }

    public User getUser(String id) {
        return users.stream().filter(u -> u.getId().equals(id)).findFirst().orElse(null);
    }
}
