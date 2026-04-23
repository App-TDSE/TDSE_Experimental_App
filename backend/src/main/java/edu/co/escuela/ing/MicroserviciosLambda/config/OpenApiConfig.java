package edu.co.escuela.ing.MicroserviciosLambda.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
    info = @Info(
        title = "Mini-Twitter API",
        version = "1.0",
        description = "RESTful API for the Mini-Twitter application. Secured with Auth0 JWT tokens. " +
                      "Public endpoints: GET /api/stream. " +
                      "Protected endpoints (JWT required): POST /api/posts, GET /api/me."
    )
)
@SecurityScheme(
    name = "bearerAuth",
    type = SecuritySchemeType.HTTP,
    scheme = "bearer",
    bearerFormat = "JWT",
    description = "Paste your Auth0 JWT access token here (without 'Bearer ' prefix)"
)
public class OpenApiConfig {
}
