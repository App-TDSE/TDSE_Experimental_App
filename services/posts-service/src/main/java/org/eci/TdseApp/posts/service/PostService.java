package org.eci.TdseApp.posts.service;

import lombok.RequiredArgsConstructor;
import org.eci.TdseApp.posts.model.Post;
import org.eci.TdseApp.posts.persistence.entity.PostEntity;
import org.eci.TdseApp.posts.persistence.repository.PostRepository;
import org.eci.TdseApp.posts.service.mapper.PostMapper;
import org.eci.TdseApp.posts.web.exception.ForbiddenActionException;
import org.eci.TdseApp.posts.web.exception.PostNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PostService {
    private final PostRepository repository;
    private final PostMapper mapper;

    @Transactional
    public Post createPost(String userId, String username, String content) {
        Post post = new Post();
        post.setUserId(userId);
        post.setUsername(username);
        post.setContent(content);

        PostEntity saved = repository.save(mapper.toEntity(post));
        return mapper.toDomain(saved);
    }

    @Transactional(readOnly = true)
    public List<Post> getAllPosts() {
        return mapper.toDomainList(repository.findAllByOrderByCreatedAtDesc());
    }

    @Transactional(readOnly = true)
    public Post getPostById(UUID postId) {
        return repository.findById(postId).map(mapper::toDomain).orElseThrow(() -> new PostNotFoundException(postId));
    }

    @Transactional
    public Post updatePost(UUID postId, String requesterUserId, String newContent) {
        PostEntity entity = repository.findById(postId).orElseThrow(() -> new PostNotFoundException(postId));
        assertOwnership(entity, requesterUserId, "update");

        entity.setContent(newContent);
        PostEntity updated = repository.save(entity);
        return mapper.toDomain(updated);
    }

    @Transactional
    public void deletePost(UUID postId, String requesterUserId) {
        PostEntity entity = repository.findById(postId).orElseThrow(() -> new PostNotFoundException(postId));
        assertOwnership(entity, requesterUserId, "delete");
        repository.delete(entity);
    }

    private void assertOwnership(PostEntity entity, String requesterUserId, String action) {
        if (requesterUserId == null || !requesterUserId.equals(entity.getUserId())) {
            throw new ForbiddenActionException("You are not allowed to " + action + " this post");
        }
    }
}
