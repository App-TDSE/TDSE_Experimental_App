package org.eci.TdseApp.posts.persistence.repository;

import org.eci.TdseApp.posts.persistence.entity.PostEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PostRepository extends JpaRepository<PostEntity, UUID> {
    List<PostEntity> findAllByOrderByCreatedAtDesc();
    List<PostEntity> findByUserIdOrderByCreatedAtDesc(String userId);
}
