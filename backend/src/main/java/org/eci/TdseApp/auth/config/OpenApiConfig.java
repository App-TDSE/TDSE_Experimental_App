package org.eci.TdseApp.auth.config;

import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@SecurityScheme(
    name = "bearer-jwt",
    type = SecuritySchemeType.HTTP,
    scheme = "bearer",
    bearerFormat = "JWT",
    description = "Paste an Auth0 access token here. Obtain one via the Auth0 SPA login flow."
)
public class OpenApiConfig {
    @Bean
    public OpenAPI tdseOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("TDSE Twitter-like API")
                .version("1.0.0")
                .description(
                    "RESTful API secured with Auth0. "
                    + "Public endpoints (GET /api/posts, GET /api/stream) require no authentication. "
                    + "Protected endpoints require a valid JWT with the appropriate scopes: "
                    + "read:posts, write:posts, read:profile."
                )
            );
    }
}
