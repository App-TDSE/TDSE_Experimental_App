package org.eci.TdseApp.user.web;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.eci.TdseApp.user.model.User;
import org.eci.TdseApp.user.persistence.entity.UserEntity;
import org.eci.TdseApp.user.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
@Tag(name = "Users", description = "Authenticated user profile and management")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    @PreAuthorize("hasAuthority('SCOPE_read:profile')")
    @Operation(
            summary = "Get current user profile",
            description = "Returns the authenticated user's profile data. Requires read:profile scope.",
            security = @SecurityRequirement(name = "bearer-jwt")
    )
    public ResponseEntity<User> getCurrentUser(@AuthenticationPrincipal Jwt jwt) {
        UserEntity entity = userService.getOrCreateFromJwt(jwt);

        User user = new User(
                entity.getId(),
                entity.getName(),
                entity.getEmail(),
                entity.getCreatedAt()
        );
        return ResponseEntity.ok(user);
    }
}
