package org.eci.TdseApp.post.service.mapper;

import org.eci.TdseApp.post.model.Post;
import org.eci.TdseApp.post.persistence.entity.PostEntity;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class PostMapper {
    public PostEntity toEntity(Post post) {
        PostEntity entity = new PostEntity();
        entity.setId(post.getPostId());
        entity.setUserId(post.getUserId());
        entity.setUsername(post.getUsername());
        entity.setContent(post.getContent());
        entity.setCreatedAt(post.getCreatedAt());
        return entity;
    }

    public Post toDomain(PostEntity entity) {
        Post post = new Post();
        post.setPostId(entity.getId());
        post.setUserId(entity.getUserId());
        post.setUsername(entity.getUsername());
        post.setContent(entity.getContent());
        post.setCreatedAt(entity.getCreatedAt());
        return post;
    }

    public List<Post> toDomainList(List<PostEntity> entities) {
        return entities.stream().map(this::toDomain).toList();
    }
}
