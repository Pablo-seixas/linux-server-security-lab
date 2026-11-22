\set ON_ERROR_STOP on

REVOKE ALL ON DATABASE security_lab FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION security_lab_owner;

CREATE TABLE IF NOT EXISTS app.maintenance_events (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_type text NOT NULL CHECK (length(event_type) BETWEEN 3 AND 80),
    details jsonb NOT NULL DEFAULT '{}'::jsonb,
    recorded_at timestamptz NOT NULL DEFAULT now()
);

REVOKE ALL ON ALL TABLES IN SCHEMA app FROM PUBLIC;
GRANT CONNECT ON DATABASE security_lab TO security_lab_app;
GRANT USAGE ON SCHEMA app TO security_lab_app;
GRANT SELECT, INSERT ON app.maintenance_events TO security_lab_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO security_lab_app;

ALTER DEFAULT PRIVILEGES FOR ROLE security_lab_owner IN SCHEMA app
    GRANT SELECT, INSERT ON TABLES TO security_lab_app;
