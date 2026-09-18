const formLogin = document.getElementById("formLogin");
const formRegistro = document.getElementById("formRegistro");
const mensajeError = document.getElementById("mensajeError");
const tabLogin = document.getElementById("tabLogin");
const tabRegistro = document.getElementById("tabRegistro");
const linkRegistro = document.getElementById("linkRegistro");
const linkLogin = document.getElementById("linkLogin");
const vistaLogin = document.getElementById("vistaLogin");
const vistaRegistro = document.getElementById("vistaRegistro");

// Ajusta esta ruta si tus archivos PHP quedan en otra carpeta
const API_BASE = "backend";

/* Cambio de pestañas: alterna entre la vista de login y la de registro */
function mostrarLogin(){
  tabLogin.classList.add("active");
  tabRegistro.classList.remove("active");
  vistaLogin.style.display = "block";
  vistaRegistro.style.display = "none";
  mensajeError.classList.remove("active");
}

function mostrarRegistro(){
  tabRegistro.classList.add("active");
  tabLogin.classList.remove("active");
  vistaRegistro.style.display = "block";
  vistaLogin.style.display = "none";
  mensajeError.classList.remove("active");
}

tabRegistro.addEventListener("click", mostrarRegistro);
tabLogin.addEventListener("click", mostrarLogin);

linkRegistro.addEventListener("click", (e)=>{
  e.preventDefault();
  mostrarRegistro();
});

if (linkLogin) {
  linkLogin.addEventListener("click", (e)=>{
    e.preventDefault();
    mostrarLogin();
  });
}

formLogin.addEventListener("submit", async function(e){

  e.preventDefault();

  const usuario = document.getElementById("usuario").value.trim();
  const contrasena = document.getElementById("contrasena").value.trim();

  if(usuario === "" || contrasena === ""){
    mostrarError("Por favor completa todos los campos.");
    return;
  }

  try {
    const respuesta = await fetch(`${API_BASE}/login.php`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ correo: usuario, contrasena })
    });

    const datos = await respuesta.json();

    if (!respuesta.ok) {
      mostrarError(datos.error || "No se pudo iniciar sesión.");
      return;
    }

    // Guarda el JWT simulado y los datos del usuario en localStorage.
    // El backend ya no confía en localStorage para saber quién eres:
    // cada llamada protegida debe mandar este token en el header
    // Authorization: Bearer <token> (ver auth.js).
    localStorage.setItem("colorinPapelin_token", datos.token);
    localStorage.setItem("colorinPapelin_usuario", JSON.stringify(datos.usuario));
    localStorage.setItem("colorinPapelin_sesion", JSON.stringify({ nombre: datos.usuario.nombre, rol: datos.usuario.rol }));

    const rol = datos.usuario.rol;

    if (rol === "Administrador") {
      window.location.href = "pag_admin/inicio.php";
    } else if (rol === "Empleado") {
      window.location.href = "empleado.html";
    } else {
      window.location.href = "index.html";
    }

  } catch (error) {
    mostrarError("No se pudo conectar con el servidor.");
  }

});

formRegistro.addEventListener("submit", async function(e){

  e.preventDefault();

  const nombre = document.getElementById("nombreReg").value.trim();
  const apellido = document.getElementById("apellidoReg").value.trim();
  const correo = document.getElementById("correoReg").value.trim();
  const telefono = document.getElementById("telefonoReg").value.trim();
  const direccion = document.getElementById("direccionReg").value.trim(); // opcional
  const contrasena = document.getElementById("contrasenaReg").value;
  const confirmar = document.getElementById("confirmarReg").value;
  const terminos = document.getElementById("terminosReg").checked;

  if(nombre === "" || apellido === "" || correo === "" || telefono === "" || contrasena === "" || confirmar === ""){
    mostrarError("Por favor completa todos los campos.");
    return;
  }

  if(contrasena.length < 8){
    mostrarError("La contraseña debe tener al menos 8 caracteres.");
    return;
  }

  if(contrasena !== confirmar){
    mostrarError("Las contraseñas no coinciden.");
    return;
  }

  if(!terminos){
    mostrarError("Debes aceptar los términos y condiciones.");
    return;
  }

  try {
    const respuesta = await fetch(`${API_BASE}/registro.php`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ nombre, apellido, correo, telefono, direccion, contrasena })
    });

    const datos = await respuesta.json();

    if (!respuesta.ok) {
      mostrarError(datos.error || "No se pudo crear la cuenta.");
      return;
    }

    mostrarLogin();

  } catch (error) {
    mostrarError("No se pudo conectar con el servidor.");
  }

});

function mostrarError(texto){

  mensajeError.textContent = texto;
  mensajeError.classList.add("active");

  setTimeout(()=>{

    mensajeError.classList.remove("active");

  },3000);

}
