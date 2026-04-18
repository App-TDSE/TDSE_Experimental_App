CREATE TABLE posts (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     VARCHAR(255)    NOT NULL,
    username    VARCHAR(100)    NOT NULL,
    content     VARCHAR(140)    NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_posts_user_id    ON posts (user_id);
CREATE INDEX idx_posts_created_at ON posts (created_at DESC);