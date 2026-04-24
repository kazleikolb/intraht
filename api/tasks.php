<?php

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/app.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {

    $stmt = $pdo->query("
        SELECT id, title, status, priority, due_date
        FROM tasks
        WHERE deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT 50
    ");

    $tasks = $stmt->fetchAll();

    jsonResponse([
        "success" => true,
        "tasks" => $tasks,
        "kpis" => [
            "open" => count(array_filter($tasks, fn($t) => $t['status'] === 'open')),
            "blocked" => count(array_filter($tasks, fn($t) => $t['status'] === 'blocked')),
            "review" => count(array_filter($tasks, fn($t) => $t['status'] === 'review')),
            "overdue" => count(array_filter($tasks, fn($t) =>
                $t['due_date'] && strtotime($t['due_date']) < time()
            )),
        ]
    ]);
}

if ($method === 'POST') {

    $input = getJsonInput();

    if (empty($input['title'])) {
        jsonResponse([
            "success" => false,
            "message" => "Titel fehlt"
        ], 400);
    }

    $stmt = $pdo->prepare("
        INSERT INTO tasks (title, priority, created_by)
        VALUES (:title, :priority, 1)
    ");

    $stmt->execute([
        "title" => $input['title'],
        "priority" => $input['priority'] ?? 'medium'
    ]);

    jsonResponse([
        "success" => true,
        "message" => "Task erstellt"
    ]);
}
