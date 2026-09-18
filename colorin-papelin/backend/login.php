<?php
// ============================================================
// login.php — Verifica correo/contraseña contra la BD (usando
// password_verify, nunca comparando texto plano) y devuelve un
// JWT simulado que el frontend guarda en localStorage.
// ============================================================

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require 'db.php';
require 'jwt_helper.php';

// En un entorno real, esta clave iría en una variable de entorno,
// nunca escrita directamente en el código fuente.
$SECRETO_JWT = "coloreando_papelin_clave_secreta_2026";

$data = json_decode(file_get_contents('php://input'), true);

$correo     = trim($data['correo'] ?? '');
$contrasena = $data['contrasena'] ?? '';

if ($correo === '' || $contrasena === '') {
    http_response_code(400);
    echo json_encode(["error" => "Completa correo y contraseña."]);
    exit;
}

$stmt = $pdo->prepare(
    "SELECT u.id_usuario, u.nombre, u.apellido, u.correo, u.contraseña, u.id_rol, r.nombre_rol
     FROM usuario u
     INNER JOIN roles r ON u.id_rol = r.id_rol
     WHERE u.correo = ?"
);
$stmt->execute([$correo]);
$usuario = $stmt->fetch(PDO::FETCH_ASSOC);

// password_verify compara el texto plano recibido contra el hash
// bcrypt guardado, sin exponer nunca la contraseña real.
if (!$usuario || !password_verify($contrasena, $usuario['contraseña'])) {
    http_response_code(401);
    echo json_encode(["error" => "Correo o contraseña incorrectos."]);
    exit;
}

$payload = [
    "sub"    => $usuario['id_usuario'],
    "nombre" => $usuario['nombre'],
    "rol"    => $usuario['nombre_rol'],
    "iat"    => time(),
    "exp"    => time() + 3600 // el token expira en 1 hora
];

$token = generarJWT($payload, $SECRETO_JWT);

echo json_encode([
    "ok"    => true,
    "token" => $token,
    "usuario" => [
        "id"       => $usuario['id_usuario'],
        "nombre"   => $usuario['nombre'],
        "apellido" => $usuario['apellido'],
        "correo"   => $usuario['correo'],
        "rol"      => $usuario['nombre_rol']
    ]
]);
