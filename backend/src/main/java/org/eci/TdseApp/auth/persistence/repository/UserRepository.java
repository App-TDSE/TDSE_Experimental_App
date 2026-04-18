package org.eci.TdseApp.auth.persistence.repository;

import org.eci.TdseApp.auth.persistence.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<UserEntity, UUID> {
    Optional<UserEntity> findByAuth0Sub(String auth0Sub);
    Optional<UserEntity> findByEmail(String email);
}