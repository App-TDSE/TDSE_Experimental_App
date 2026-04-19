package org.eci.TdseApp.posts.service.mapper;

import org.eci.TdseApp.posts.model.Post;
import org.eci.TdseApp.posts.persistence.entity.PostEntity;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class PostMapper {
    public Post toDomain(PostEntity entity) {
        return new Post(
                entity.getId(),
                entity.getUsername(),
                entity.getContent(),
                entity.getCreatedAt(),
                entity.getUserId()
        );
    }

    public PostEntity toEntity(Post domain) {
        PostEntity entity = new PostEntity();
        entity.setId(domain.getPostId());
        entity.setUserId(domain.getUserId());
        entity.setUsername(domain.getUsername());
        entity.setContent(domain.getContent());
        entity.setCreatedAt(domain.getCreatedAt());
        return entity;
    }

    public List<Post> toDomainList(List<PostEntity> entities) {
        return entities.stream().map(this::toDomain).toList();
    }
}
