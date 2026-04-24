<?php

header("Content-Type: application/json; charset=utf-8");

function jsonResponse($data, $status = 200) {
    http_response_code($status);
    echo json_encode($data);
    exit;
}

function getJsonInput() {
    return json_decode(file_get_contents("php://input"), true);
}
