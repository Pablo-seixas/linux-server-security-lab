BEGIN;

-- Default privileges grant SELECT and INSERT on new app tables. This table is
-- deliberately read-only for the application role, so override that default
-- and repair databases initialized before this migration was added.
REVOKE ALL ON TABLE app.football_matches FROM security_lab_app;
GRANT SELECT ON TABLE app.football_matches TO security_lab_app;

COMMIT;
