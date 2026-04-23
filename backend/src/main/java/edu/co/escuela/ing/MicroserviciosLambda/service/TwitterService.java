package edu.co.escuela.ing.MicroserviciosLambda.service;

import edu.co.escuela.ing.MicroserviciosLambda.model.Post;
import edu.co.escuela.ing.MicroserviciosLambda.repository.PostRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class TwitterService {

    private final PostRepository postRepository;

    public TwitterService(PostRepository postRepository) {
        this.postRepository = postRepository;
    }

    public List<Post> getAllPosts() {
        return postRepository.findAllByOrderByTimestampDesc();
    }

    public Post createPost(String content, String authorId) {
        if (content == null || content.trim().isEmpty()) {
            throw new IllegalArgumentException("Post content cannot be empty");
        }
        if (content.length() > 140) {
            throw new IllegalArgumentException("Post exceeds 140 characters limit");
        }
        Post post = new Post(UUID.randomUUID().toString(), content, authorId, LocalDateTime.now());
        return postRepository.save(post);
    }
}
