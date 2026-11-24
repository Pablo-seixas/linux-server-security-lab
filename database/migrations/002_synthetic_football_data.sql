BEGIN;

CREATE TABLE app.football_matches (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    played_at TIMESTAMPTZ NOT NULL,
    home_team TEXT NOT NULL CHECK (length(home_team) BETWEEN 3 AND 80),
    away_team TEXT NOT NULL CHECK (length(away_team) BETWEEN 3 AND 80),
    home_score SMALLINT NOT NULL CHECK (home_score BETWEEN 0 AND 30),
    away_score SMALLINT NOT NULL CHECK (away_score BETWEEN 0 AND 30),
    venue TEXT NOT NULL CHECK (length(venue) BETWEEN 3 AND 100),
    CHECK (home_team <> away_team)
);

COMMENT ON TABLE app.football_matches IS
    'Fictional synthetic records created for security-lab testing.';

INSERT INTO app.football_matches
    (played_at, home_team, away_team, home_score, away_score, venue)
VALUES
    ('2026-10-03T18:00:00Z', 'Bahia Solar FC', 'Recife Harbor SC', 2, 1, 'Aurora Stadium'),
    ('2026-10-10T20:30:00Z', 'Sertao United', 'Salvador Tech AC', 0, 0, 'Mandacaru Arena'),
    ('2026-10-17T19:00:00Z', 'Recife Harbor SC', 'Sertao United', 3, 2, 'Atlantic Field'),
    ('2026-10-24T21:00:00Z', 'Salvador Tech AC', 'Bahia Solar FC', 1, 4, 'Open Source Park'),
    ('2026-10-31T17:30:00Z', 'Bahia Solar FC', 'Sertao United', 2, 2, 'Aurora Stadium'),
    ('2026-11-07T18:30:00Z', 'Recife Harbor SC', 'Salvador Tech AC', 1, 0, 'Atlantic Field');

REVOKE ALL ON TABLE app.football_matches FROM PUBLIC;
REVOKE ALL ON TABLE app.football_matches FROM security_lab_app;
GRANT SELECT ON TABLE app.football_matches TO security_lab_app;

COMMIT;
