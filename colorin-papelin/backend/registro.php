<?php
// ============================================================
// registro.php — Crea una cuenta nueva. La contraseña se guarda
// encriptada con bcrypt (password_hash), nunca en texto plano.
// ============================================================

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require 'db.php';

$data = json_decode(file_get_contents('php://input'), true);

$nombre      = trim($data['nombre'] ?? '');
$apellido    = trim($data['apellido'] ?? '');
$correo      = trim($data['correo'] ?? '');
$telefono    = trim($data['telefono'] ?? '');
$direccion   = trim($data['direccion'] ?? '');
$contrasena  = $data['contrasena'] ?? '';

// --- Validaciones básicas ---
if ($nombre === '' || $apellido === '' || $correo === '' || $contrasena === '') {
    http_response_code(400);
    echo json_encode(["error" => "Faltan campos obligatorios."]);
    exit;
}

if (!filter_var($correo, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(["error" => "El correo no es válido."]);
    exit;
}

if (strlen($contrasena) < 8) {
    http_response_code(400);
    echo json_encode(["error" => "La contraseña debe tener al menos 8 caracteres."]);
    exit;
}

// --- Verificar que el correo no exista ya ---
$stmt = $pdo->prepare("SELECT id_usuario FROM usuario WHERE correo = ?");
$stmt->execute([$correo]);
if ($stmt->fetch()) {
    http_response_code(409);
    echo json_encode(["error" => "Ya existe una cuenta con ese correo."]);
    exit;
}

// --- Encriptar la contraseña con bcrypt (nunca texto plano) ---
$hash = password_hash($contrasena, PASSWORD_BCRYPT);

// id_rol = 3 -> Cliente (ver tabla roles). El registro público siempre
// crea clientes; Administrador/Empleado se crean desde el panel admin.
$stmt = $pdo->prepare(
    "INSERT INTO usuario (nombre, apellido, correo, contraseña, telefono, telefono_secundario, direccion, id_rol)
     VALUES (?, ?, ?, ?, ?, NULL, ?, 3)"
);
$stmt->execute([$nombre, $apellido, $correo, $hash, $telefono, $direccion]);

echo json_encode([
    "ok" => true,
    "mensaje" => "Cuenta creada correctamente. Ya puedes iniciar sesión."
]);
