-- Создаём таблицу пользователей

CREATE TABLE IF NOT EXISTS users (
    id            UUID PRIMARY KEY,
    login         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- (опционально) индекс по логину, но UNIQUE уже его создаёт
-- CREATE UNIQUE INDEX users_login_uindex ON users (login);

-- Группы (папки), иерархия через parent_id

CREATE TABLE IF NOT EXISTS groups (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL,
    parent_id   UUID NULL,
    name        TEXT NOT NULL,
    description TEXT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Внешний ключ на владельца
ALTER TABLE groups
    ADD CONSTRAINT fk_groups_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE;

-- Внешний ключ на родительскую группу (для иерархии)
ALTER TABLE groups
    ADD CONSTRAINT fk_groups_parent
    FOREIGN KEY (parent_id) REFERENCES groups(id)
    ON DELETE CASCADE;

-- Индексы для быстрых выборок по пользователю и имени
CREATE INDEX IF NOT EXISTS idx_groups_user_id ON groups(user_id);
CREATE INDEX IF NOT EXISTS idx_groups_user_id_name ON groups(user_id, name);


-- Записи внутри групп

CREATE TABLE IF NOT EXISTS records (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL,
    group_id    UUID NOT NULL,
    title       TEXT NOT NULL,
    description TEXT NULL,
    data        JSONB NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Внешние ключи

ALTER TABLE records
    ADD CONSTRAINT fk_records_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE;

ALTER TABLE records
    ADD CONSTRAINT fk_records_group
    FOREIGN KEY (group_id) REFERENCES groups(id)
    ON DELETE CASCADE;

-- Индексы для поиска

CREATE INDEX IF NOT EXISTS idx_records_user_id ON records(user_id);
CREATE INDEX IF NOT EXISTS idx_records_user_id_title ON records(user_id, title);
-- По JSONB можно будет добавить GIN-индекс при необходимости:
-- CREATE INDEX IF NOT EXISTS idx_records_data_gin ON records USING GIN (data);


-- Теги, локальные для каждого пользователя

CREATE TABLE IF NOT EXISTS tags (
    id      UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    name    TEXT NOT NULL
);

ALTER TABLE tags
    ADD CONSTRAINT fk_tags_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE;

-- Уникальность имени тега в рамках одного пользователя
ALTER TABLE tags
    ADD CONSTRAINT uq_tags_user_name UNIQUE (user_id, name);

CREATE INDEX IF NOT EXISTS idx_tags_user_id ON tags(user_id);
CREATE INDEX IF NOT EXISTS idx_tags_user_id_name ON tags(user_id, name);


-- Связка тегов с группами

CREATE TABLE IF NOT EXISTS group_tags (
    tag_id   UUID NOT NULL,
    group_id UUID NOT NULL,
    PRIMARY KEY (tag_id, group_id)
);

ALTER TABLE group_tags
    ADD CONSTRAINT fk_group_tags_tag
    FOREIGN KEY (tag_id) REFERENCES tags(id)
    ON DELETE CASCADE;

ALTER TABLE group_tags
    ADD CONSTRAINT fk_group_tags_group
    FOREIGN KEY (group_id) REFERENCES groups(id)
    ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_group_tags_group_id ON group_tags(group_id);


-- Связка тегов с записями

CREATE TABLE IF NOT EXISTS record_tags (
    tag_id    UUID NOT NULL,
    record_id UUID NOT NULL,
    PRIMARY KEY (tag_id, record_id)
);

ALTER TABLE record_tags
    ADD CONSTRAINT fk_record_tags_tag
    FOREIGN KEY (tag_id) REFERENCES tags(id)
    ON DELETE CASCADE;

ALTER TABLE record_tags
    ADD CONSTRAINT fk_record_tags_record
    FOREIGN KEY (record_id) REFERENCES records(id)
    ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_record_tags_record_id ON record_tags(record_id);

-- Вложения (файлы/картинки) к записям

CREATE TABLE IF NOT EXISTS attachments (
    id         UUID PRIMARY KEY,
    record_id  UUID NOT NULL,
    file_name  TEXT NOT NULL,
    file_path  TEXT NOT NULL,
    mime_type  TEXT NULL,
    size_bytes BIGINT NOT NULL
);

ALTER TABLE attachments
    ADD CONSTRAINT fk_attachments_record
    FOREIGN KEY (record_id) REFERENCES records(id)
    ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_attachments_record_id ON attachments(record_id);



