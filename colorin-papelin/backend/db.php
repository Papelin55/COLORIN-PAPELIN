<?php
// ============================================================
// db.php — Conexión PDO a la base de datos colorinpapelin_def
// ============================================================

$host   = "localhost";
$dbname = "colorinpapelin_def";
$user   = "root";       // ajusta si tu MySQL/MariaDB usa otro usuario
$pass   = "";            // ajusta si tu MySQL/MariaDB tiene contraseña

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $user,
        $pass
    );
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode(["error" => "Error de conexión a la base de datos."]);
    exit;
}
