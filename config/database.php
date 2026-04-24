<?php

$DB_HOST = 'localhost'; // bei IONOS meist korrekt
$DB_NAME = 'intrath';
$DB_USER = 'DEIN_DB_USER';
$DB_PASS = 'DEIN_PASSWORT';

try {
    $pdo = new PDO(
        "mysql:host=$DB_HOST;dbname=$DB_NAME;charset=utf8mb4",
        $DB_USER,
        $DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Datenbankverbindung fehlgeschlagen"
    ]);
    exit;
}
