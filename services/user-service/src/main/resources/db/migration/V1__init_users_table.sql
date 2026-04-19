CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    auth0_sub   VARCHAR(255)    NOT NULL,
    name        VARCHAR(255)    NOT NULL,
    email       VARCHAR(255)    NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT uk_users_auth0_sub UNIQUE (auth0_sub)
);

CREATE INDEX idx_users_auth0_sub ON users (auth0_sub);
CREATE INDEX idx_users_email ON users (email);
