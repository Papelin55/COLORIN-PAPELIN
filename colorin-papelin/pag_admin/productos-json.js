

const API = "http://localhost:3000/productos";

let productosCache = [];

const modalEl = document.getElementById("modalProducto");
const modal = new bootstrap.Modal(modalEl);
const toastEl = document.getElementById("toast");
const toast = new bootstrap.Toast(toastEl, { delay: 2500 });

// ------------------------------------------------------------
// GET — cargar todos los productos y pintar tabla + estadísticas
// ------------------------------------------------------------
async function cargarProductos() {
  try {
    const respuesta = await fetch(API);
    productosCache = await respuesta.json();
    pintarTabla(productosCache);
    pintarEstadisticas(productosCache);
  } catch (error) {
    mostrarToast("No se pudo conectar con JSON Server. ¿Está corriendo en el puerto 3000?");
  }
}

function pintarEstadisticas(lista) {
  document.getElementById("statTotal").textContent = lista.length;
  document.getElementById("statStockBajo").textContent =
    lista.filter(p => Number(p.stock) <= Number(p.stockMinimo)).length;
  document.getElementById("statFeatured").textContent =
    lista.filter(p => p.featured).length;
  const valorTotal = lista.reduce((acc, p) => acc + Number(p.price) * Number(p.stock), 0);
  document.getElementById("statValor").textContent =
    "$" + valorTotal.toLocaleString("es-CO");
}

function pintarTabla(lista) {
  const tbody = document.getElementById("tablaProductos");
  tbody.innerHTML = "";

  if (lista.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-center text-muted py-4">No hay productos.</td></tr>`;
    return;
  }

  lista.forEach((p) => {
    const stockBajo = Number(p.stock) <= Number(p.stockMinimo);
    const fila = document.createElement("tr");
    fila.innerHTML = `
      <td>${p.id}</td>
      <td>
        <div class="fw-semibold">${p.name}</div>
        <div class="text-muted small">${p.desc || ""}</div>
      </td>
      <td><span class="badge badge-cat-${p.categoria}">Cat. ${p.categoria}</span></td>
      <td>$${Number(p.price).toLocaleString("es-CO")}</td>
      <td class="${stockBajo ? "stock-bajo" : ""}">
        ${p.stock} ${stockBajo ? '<i class="fas fa-triangle-exclamation"></i>' : ""}
      </td>
      <td>${p.featured ? '<i class="fas fa-star text-warning"></i>' : "—"}</td>
      <td>
        <button class="btn btn-sm btn-outline-primary" onclick="abrirEditar('${p.id}')"><i class="fas fa-pen"></i></button>
        <button class="btn btn-sm btn-outline-danger" onclick="borrarProducto('${p.id}')"><i class="fas fa-trash"></i></button>
      </td>
    `;
    tbody.appendChild(fila);
  });
}

// ------------------------------------------------------------
// Buscador (filtra sobre lo ya cargado, sin nuevo fetch)
// ------------------------------------------------------------
document.getElementById("buscador").addEventListener("input", (e) => {
  const texto = e.target.value.toLowerCase();
  const filtrados = productosCache.filter(p => p.name.toLowerCase().includes(texto));
  pintarTabla(filtrados);
});

// ------------------------------------------------------------
// Abrir modal: nuevo
// ------------------------------------------------------------
document.getElementById("btnNuevo").addEventListener("click", () => {
  document.getElementById("modalTitulo").textContent = "Nuevo producto";
  document.getElementById("formProducto").reset();
  document.getElementById("pId").value = "";
  modal.show();
});

// ------------------------------------------------------------
// Abrir modal: editar (precargado)
// ------------------------------------------------------------
function abrirEditar(id) {
  const p = productosCache.find(x => String(x.id) === String(id));
  if (!p) return;

  document.getElementById("modalTitulo").textContent = "Editar producto";
  document.getElementById("pId").value = p.id;
  document.getElementById("pName").value = p.name;
  document.getElementById("pDesc").value = p.desc || "";
  document.getElementById("pPrice").value = p.price;
  document.getElementById("pCategoria").value = p.categoria;
  document.getElementById("pStock").value = p.stock;
  document.getElementById("pStockMinimo").value = p.stockMinimo;
  document.getElementById("pProveedor").value = p.proveedor;
  document.getElementById("pFeatured").checked = !!p.featured;

  modal.show();
}

// ------------------------------------------------------------
// Guardar (POST si es nuevo, PUT si ya existe)
// ------------------------------------------------------------
document.getElementById("formProducto").addEventListener("submit", async (e) => {
  e.preventDefault();

  const idExistente = document.getElementById("pId").value;

  const producto = {
    name: document.getElementById("pName").value.trim(),
    desc: document.getElementById("pDesc").value.trim(),
    price: Number(document.getElementById("pPrice").value),
    categoria: Number(document.getElementById("pCategoria").value),
    stock: Number(document.getElementById("pStock").value),
    stockMinimo: Number(document.getElementById("pStockMinimo").value),
    proveedor: Number(document.getElementById("pProveedor").value),
    featured: document.getElementById("pFeatured").checked,
    icon: "fas fa-box"
  };

  try {
    if (idExistente) {
      await fetch(`${API}/${idExistente}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: idExistente, ...producto })
      });
      mostrarToast("Producto actualizado — ya se refleja en el catálogo del cliente.");
    } else {
      await fetch(API, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(producto)
      });
      mostrarToast("Producto creado — ya aparece en el catálogo del cliente.");
    }

    modal.hide();
    cargarProductos();
  } catch (error) {
    mostrarToast("Ocurrió un error al guardar.");
  }
});

// ------------------------------------------------------------
// DELETE
// ------------------------------------------------------------
async function borrarProducto(id) {
  if (!confirm("¿Seguro que quieres borrar este producto? También desaparecerá del catálogo del cliente.")) return;

  try {
    await fetch(`${API}/${id}`, { method: "DELETE" });
    mostrarToast("Producto borrado.");
    cargarProductos();
  } catch (error) {
    mostrarToast("Ocurrió un error al borrar.");
  }
}

function mostrarToast(mensaje) {
  document.getElementById("toastMsg").textContent = mensaje;
  toast.show();
}

cargarProductos();
