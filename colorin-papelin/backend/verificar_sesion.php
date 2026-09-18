<?php
// ============================================================
// verificar_sesion.php — Ejemplo de ruta protegida. Cualquier
// endpoint que solo deba usar un usuario logueado (panel admin,
// panel empleado, etc.) debe empezar revisando el token así.
// ============================================================

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require 'jwt_helper.php';

$SECRETO_JWT = "coloreando_papelin_clave_secreta_2026";

// El token llega en el header: Authorization: Bearer <token>
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? '';

if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    http_response_code(401);
    echo json_encode(["error" => "No se envió un token."]);
    exit;
}

$token = $matches[1];
$payload = verificarJWT($token, $SECRETO_JWT);

if ($payload === false) {
    http_response_code(401);
    echo json_encode(["error" => "Token inválido o expirado. Vuelve a iniciar sesión."]);
    exit;
}

// Si llegó hasta aquí, el token es válido: $payload trae id, nombre y rol.
echo json_encode([
    "ok" => true,
    "sesion" => $payload
]);
