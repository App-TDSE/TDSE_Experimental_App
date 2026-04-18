package org.eci.TdseApp.auth.model;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@AllArgsConstructor
public class User {
    private UUID userId;
    private String name;
    private String email;
    private Instant createdAt;
}
