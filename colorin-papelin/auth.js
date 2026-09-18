// ============================================================
// auth.js — Inclúyelo en cualquier página protegida (panel de
// administrador, panel de empleado). Revisa que exista un JWT
// válido en localStorage; si no, devuelve al usuario al login.
//
// Uso: <script src="../auth.js"></script>  (ajusta la ruta)
// Opcional: protegerPagina(["Administrador"]) si solo un rol
// puede ver esa página.
// ============================================================

function obtenerSesion() {
  const token = localStorage.getItem("colorinPapelin_token");
  const usuarioJSON = localStorage.getItem("colorinPapelin_usuario");

  if (!token || !usuarioJSON) return null;

  // Decodifica el payload del JWT (solo para leer, la validación
  // real de la firma la hace siempre el backend en verificar_sesion.php)
  try {
    const payloadBase64 = token.split(".")[1];
    const payload = JSON.parse(atob(payloadBase64.replace(/-/g, "+").replace(/_/g, "/")));

    if (payload.exp && Date.now() / 1000 > payload.exp) {
      cerrarSesion();
      return null;
    }

    return { token, usuario: JSON.parse(usuarioJSON), payload };
  } catch (e) {
    return null;
  }
}

function protegerPagina(rolesPermitidos = null) {
  const sesion = obtenerSesion();

  if (!sesion) {
    window.location.href = "login-v2.html";
    return;
  }

  if (rolesPermitidos && !rolesPermitidos.includes(sesion.usuario.rol)) {
    alert("No tienes permiso para ver esta página.");
    window.location.href = "index.html";
  }
}

function cerrarSesion() {
  localStorage.removeItem("colorinPapelin_token");
  localStorage.removeItem("colorinPapelin_usuario");
  window.location.href = "login-v2.html";
}

// Ejemplo de cómo llamar a una ruta protegida del backend
// mandando el token en el header Authorization:
async function fetchProtegido(url, opciones = {}) {
  const sesion = obtenerSesion();
  if (!sesion) {
    window.location.href = "login-v2.html";
    return;
  }

  return fetch(url, {
    ...opciones,
    headers: {
      ...(opciones.headers || {}),
      "Authorization": `Bearer ${sesion.token}`
    }
  });
}
