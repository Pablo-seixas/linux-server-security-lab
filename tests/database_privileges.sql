\set ON_ERROR_STOP on

\echo 'Database privilege verification (application role)'

DO $privilege_test$
BEGIN
    IF current_user = 'security_lab_app' THEN
        RAISE NOTICE 'PASS identity: current_user is security_lab_app';
    ELSE
        RAISE EXCEPTION 'FAIL identity: test must run as security_lab_app (actual: %)', current_user;
    END IF;

    IF has_database_privilege(current_user, current_database(), 'CONNECT') THEN
        RAISE NOTICE 'PASS database: CONNECT is granted';
    ELSE
        RAISE EXCEPTION 'FAIL database: CONNECT must be granted';
    END IF;

    IF NOT has_database_privilege(current_user, current_database(), 'CREATE') THEN
        RAISE NOTICE 'PASS database: CREATE is denied';
    ELSE
        RAISE EXCEPTION 'FAIL database: CREATE must be denied';
    END IF;

    IF NOT has_database_privilege(current_user, current_database(), 'TEMP') THEN
        RAISE NOTICE 'PASS database: TEMP is denied';
    ELSE
        RAISE EXCEPTION 'FAIL database: TEMP must be denied';
    END IF;

    IF has_schema_privilege(current_user, 'app', 'USAGE') THEN
        RAISE NOTICE 'PASS schema app: USAGE is granted';
    ELSE
        RAISE EXCEPTION 'FAIL schema app: USAGE must be granted';
    END IF;

    IF NOT has_schema_privilege(current_user, 'app', 'CREATE') THEN
        RAISE NOTICE 'PASS schema app: CREATE is denied';
    ELSE
        RAISE EXCEPTION 'FAIL schema app: CREATE must be denied';
    END IF;

    IF to_regclass('app.maintenance_events') IS NOT NULL THEN
        RAISE NOTICE 'PASS table: app.maintenance_events exists';
    ELSE
        RAISE EXCEPTION 'FAIL table: app.maintenance_events is missing';
    END IF;

    IF has_table_privilege(current_user, 'app.maintenance_events', 'SELECT') THEN
        RAISE NOTICE 'PASS maintenance_events: SELECT is granted';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events: SELECT must be granted';
    END IF;

    IF has_table_privilege(current_user, 'app.maintenance_events', 'INSERT') THEN
        RAISE NOTICE 'PASS maintenance_events: INSERT is granted';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events: INSERT must be granted';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.maintenance_events', 'UPDATE') THEN
        RAISE NOTICE 'PASS maintenance_events: UPDATE is denied';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events: UPDATE must be denied';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.maintenance_events', 'DELETE') THEN
        RAISE NOTICE 'PASS maintenance_events: DELETE is denied';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events: DELETE must be denied';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.maintenance_events', 'TRUNCATE') THEN
        RAISE NOTICE 'PASS maintenance_events: TRUNCATE is denied';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events: TRUNCATE must be denied';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.maintenance_events', 'REFERENCES') THEN
        RAISE NOTICE 'PASS maintenance_events: REFERENCES is denied';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events: REFERENCES must be denied';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.maintenance_events', 'TRIGGER') THEN
        RAISE NOTICE 'PASS maintenance_events: TRIGGER is denied';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events: TRIGGER must be denied';
    END IF;

    IF has_sequence_privilege(current_user, 'app.maintenance_events_id_seq', 'USAGE') THEN
        RAISE NOTICE 'PASS maintenance_events sequence: USAGE is granted';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events sequence: USAGE must be granted';
    END IF;

    IF has_sequence_privilege(current_user, 'app.maintenance_events_id_seq', 'SELECT') THEN
        RAISE NOTICE 'PASS maintenance_events sequence: SELECT is granted';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events sequence: SELECT must be granted';
    END IF;

    IF NOT has_sequence_privilege(current_user, 'app.maintenance_events_id_seq', 'UPDATE') THEN
        RAISE NOTICE 'PASS maintenance_events sequence: UPDATE is denied';
    ELSE
        RAISE EXCEPTION 'FAIL maintenance_events sequence: UPDATE must be denied';
    END IF;

    IF to_regclass('app.football_matches') IS NOT NULL THEN
        RAISE NOTICE 'PASS table: app.football_matches exists';
    ELSE
        RAISE EXCEPTION 'FAIL table: app.football_matches is missing';
    END IF;

    IF has_table_privilege(current_user, 'app.football_matches', 'SELECT') THEN
        RAISE NOTICE 'PASS football_matches: SELECT is granted';
    ELSE
        RAISE EXCEPTION 'FAIL football_matches: SELECT must be granted';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.football_matches', 'INSERT') THEN
        RAISE NOTICE 'PASS football_matches: INSERT is denied';
    ELSE
        RAISE EXCEPTION 'FAIL football_matches: INSERT must be denied';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.football_matches', 'UPDATE') THEN
        RAISE NOTICE 'PASS football_matches: UPDATE is denied';
    ELSE
        RAISE EXCEPTION 'FAIL football_matches: UPDATE must be denied';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.football_matches', 'DELETE') THEN
        RAISE NOTICE 'PASS football_matches: DELETE is denied';
    ELSE
        RAISE EXCEPTION 'FAIL football_matches: DELETE must be denied';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.football_matches', 'TRUNCATE') THEN
        RAISE NOTICE 'PASS football_matches: TRUNCATE is denied';
    ELSE
        RAISE EXCEPTION 'FAIL football_matches: TRUNCATE must be denied';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.football_matches', 'REFERENCES') THEN
        RAISE NOTICE 'PASS football_matches: REFERENCES is denied';
    ELSE
        RAISE EXCEPTION 'FAIL football_matches: REFERENCES must be denied';
    END IF;

    IF NOT has_table_privilege(current_user, 'app.football_matches', 'TRIGGER') THEN
        RAISE NOTICE 'PASS football_matches: TRIGGER is denied';
    ELSE
        RAISE EXCEPTION 'FAIL football_matches: TRIGGER must be denied';
    END IF;

    IF (SELECT count(*) FROM app.football_matches) = 6 THEN
        RAISE NOTICE 'PASS football_matches: six synthetic fixture rows are readable';
    ELSE
        RAISE EXCEPTION 'FAIL football_matches: expected six synthetic fixture rows';
    END IF;
END
$privilege_test$;

BEGIN;
INSERT INTO app.maintenance_events (event_type, details)
VALUES ('privilege-test', '{"source":"database_privileges.sql"}'::jsonb);
ROLLBACK;
\echo 'PASS maintenance_events: representative INSERT succeeds and is rolled back'

\echo 'Database privilege verification passed.'
