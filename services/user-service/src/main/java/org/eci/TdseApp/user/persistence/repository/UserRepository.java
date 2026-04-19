package org.eci.TdseApp.user.persistence.repository;

import org.eci.TdseApp.user.persistence.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<UserEntity, UUID> {
    Optional<UserEntity> findByAuth0Sub(String auth0Sub);
    Optional<UserEntity> findByEmail(String email);
}
