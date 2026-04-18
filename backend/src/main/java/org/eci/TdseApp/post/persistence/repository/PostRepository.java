package org.eci.TdseApp.post.persistence.repository;

import org.eci.TdseApp.post.persistence.entity.PostEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PostRepository extends JpaRepository<PostEntity, UUID> {
    List<PostEntity> findAllByOrderByCreatedAtDesc();
}
