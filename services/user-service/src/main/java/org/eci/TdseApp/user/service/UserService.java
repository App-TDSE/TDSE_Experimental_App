package org.eci.TdseApp.user.service;

import org.eci.TdseApp.user.persistence.entity.UserEntity;
import org.eci.TdseApp.user.persistence.repository.UserRepository;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

@Service
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional
    public UserEntity getOrCreateFromJwt(Jwt jwt) {
        String auth0Sub = jwt.getSubject();

        Optional<UserEntity> existing = userRepository.findByAuth0Sub(auth0Sub);
        if (existing.isPresent()) {
            return existing.get();
        }

        UserEntity user = new UserEntity();
        user.setAuth0Sub(auth0Sub);

        String email = jwt.getClaimAsString("email");
        String name = jwt.getClaimAsString("name");
        if (email == null) {
            email = jwt.getClaimAsString("https://tdseapp.api/email");
        }
        if (name == null) {
            name = jwt.getClaimAsString("https://tdseapp.api/name");
        }

        user.setEmail(email != null ? email : auth0Sub);
        user.setName(name != null ? name : "User");
        return userRepository.save(user);
    }

    public Optional<UserEntity> findByAuth0Sub(String auth0Sub) {
        return userRepository.findByAuth0Sub(auth0Sub);
    }

    public Optional<UserEntity> findById(UUID userId) {
        return userRepository.findById(userId);
    }
}
