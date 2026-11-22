<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);

if (!in_array($path, ['/health', '/api/matches'], true)) {
    http_response_code(404);
    echo json_encode(['status' => 'not_found'], JSON_THROW_ON_ERROR);
    exit;
}

$startedAt = hrtime(true);

try {
    $dsn = sprintf(
        'pgsql:host=%s;port=%s;dbname=%s;sslmode=disable',
        getenv('DB_HOST') ?: 'postgres',
        getenv('DB_PORT') ?: '5432',
        getenv('DB_NAME') ?: 'security_lab'
    );

    $database = new PDO(
        $dsn,
        getenv('DB_USER') ?: '',
        getenv('DB_PASSWORD') ?: '',
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_TIMEOUT => 3,
        ]
    );
    if ($path === '/api/matches') {
        $statement = $database->query(
            'SELECT played_at, home_team, away_team, home_score, away_score, venue '
            . 'FROM app.football_matches ORDER BY played_at DESC, id DESC LIMIT 50'
        );
        echo json_encode(
            [
                'data_license' => 'CC0-style synthetic test data; no real-world records.',
                'matches' => $statement->fetchAll(),
            ],
            JSON_THROW_ON_ERROR
        );
        exit;
    }

    $database->query('SELECT 1')->fetchColumn();

    echo json_encode(
        [
            'status' => 'healthy',
            'database' => 'reachable',
            'latency_ms' => round((hrtime(true) - $startedAt) / 1_000_000, 2),
        ],
        JSON_THROW_ON_ERROR
    );
} catch (Throwable $exception) {
    error_log(json_encode([
        'event' => 'health_check_failed',
        'exception' => get_class($exception),
    ], JSON_THROW_ON_ERROR));
    http_response_code(503);
    echo json_encode(
        ['status' => 'unhealthy', 'database' => 'unreachable'],
        JSON_THROW_ON_ERROR
    );
}
