\set ON_ERROR_STOP on

SELECT current_user AS tested_role;
SELECT has_database_privilege(current_user, current_database(), 'CONNECT')
    AS can_connect;
SELECT has_schema_privilege(current_user, 'app', 'USAGE') AS can_use_schema;
SELECT has_table_privilege(
    current_user,
    'app.maintenance_events',
    'SELECT,INSERT'
) AS expected_table_access;
SELECT has_table_privilege(
    current_user,
    'app.maintenance_events',
    'UPDATE,DELETE,TRUNCATE,TRIGGER'
) AS forbidden_table_access;
