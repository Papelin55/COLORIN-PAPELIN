<?php
// ============================================================
// jwt_helper.php — Generación y verificación de un JWT simple
// (HS256), sin librerías externas, para simular autenticación
// por token como pide el entregable del Trimestre 3.
// ============================================================

function base64url_encode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode($data) {
    $pad = strlen($data) % 4;
    if ($pad > 0) {
        $data .= str_repeat('=', 4 - $pad);
    }
    return base64_decode(strtr($data, '-_', '+/'));
}

// Genera un JWT firmado a partir de un arreglo $payload y una clave secreta
function generarJWT($payload, $secreto) {
    $header = json_encode(["alg" => "HS256", "typ" => "JWT"]);
    $payloadJson = json_encode($payload);

    $headerEnc  = base64url_encode($header);
    $payloadEnc = base64url_encode($payloadJson);

    $firma = hash_hmac('sha256', "$headerEnc.$payloadEnc", $secreto, true);
    $firmaEnc = base64url_encode($firma);

    return "$headerEnc.$payloadEnc.$firmaEnc";
}

// Verifica la firma y la expiración de un JWT. Devuelve el payload
// como arreglo si es válido, o false si no lo es.
function verificarJWT($jwt, $secreto) {
    $partes = explode('.', $jwt);
    if (count($partes) !== 3) {
        return false;
    }

    list($headerEnc, $payloadEnc, $firmaEnc) = $partes;

    $firmaEsperada = hash_hmac('sha256', "$headerEnc.$payloadEnc", $secreto, true);
    $firmaRecibida = base64url_decode($firmaEnc);

    if (!hash_equals($firmaEsperada, $firmaRecibida)) {
        return false; // la firma no coincide -> el token fue alterado
    }

    $payload = json_decode(base64url_decode($payloadEnc), true);

    if (isset($payload['exp']) && time() > $payload['exp']) {
        return false; // el token ya expiró
    }

    return $payload;
}
