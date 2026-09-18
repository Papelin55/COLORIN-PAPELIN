// ==========================================
// CONTROL DE PESTAÑAS CON PERSISTENCIA
// ==========================================

const TAB_TITLES = {
    'dashboard': 'Dashboard General',
    'productos': 'Gestión de Productos',
    'categorias': 'Categorías de Producto',
    'proveedores': 'Directorio de Proveedores',
    'compras': 'Compras a Proveedores',
    'descuentos': 'Administración de Descuentos',
    'metodospago': 'Métodos de Pago',
    'pedidos': 'Pedidos de Clientes',
    'ventas': 'Ventas y Estadísticas',
    'usuarios': 'Gestión de Usuarios',
    'roles': 'Roles del Sistema',
    'logs': 'Registros y Logs del Sistema'
};

// CAMBIO DE PESTAÑAS (Guarda la pestaña activa)
function switchTab(tabId) {
    const tabs = document.querySelectorAll('.tab-content');
    tabs.forEach(tab => tab.classList.remove('active'));

    const buttons = document.querySelectorAll('.nav-btn');
    buttons.forEach(btn => btn.classList.remove('active'));

    const selectedTab = document.getElementById(`tab-${tabId}`);
    if (selectedTab) {
        selectedTab.classList.add('active');
    }

    const titleContainer = document.getElementById('section-title');
    if (titleContainer) {
        titleContainer.innerText = TAB_TITLES[tabId] || 'Panel Admin';
    }

    if (event && event.currentTarget && event.currentTarget.classList) {
        event.currentTarget.classList.add('active');
    }

    // GUARDA EN EL NAVEGADOR LA PESTAÑA DONDE ESTÁS
    localStorage.setItem('pestana_activa_colorin', tabId);

    if (tabId === 'ventas') {
        renderSalesChart();
    }
}

// AL RECARGAR LA PÁGINA (Abre la última pestaña guardada)
document.addEventListener('DOMContentLoaded', function() {
    initDescuentos();

    // Lee la memoria del navegador para saber dónde estabas
    const ultimaPestana = localStorage.getItem('pestana_activa_colorin') || 'dashboard';
    
    // Abre automáticamente esa pestaña
    switchTab(ultimaPestana);
});


// ==========================================
// FUNCIONES PARA MODALES (CREAR / EDITAR)
// ==========================================
function openModal(modalType) {
    const modal = document.getElementById('modal-container');
    const title = document.getElementById('modal-title');
    
    if (title) title.innerText = `Añadir Nuevo (${modalType.replace('modal-', '')})`;
    if (modal) modal.style.display = 'flex';
}

function closeModal() {
    const modal = document.getElementById('modal-container');
    if (modal) modal.style.display = 'none';
}

function handleFormSubmit(event) {
    event.preventDefault();
    alert('¡Registro guardado con éxito! (Simulación Frontend)');
    closeModal();
}

// FUNCIONALIDAD DE BOTONES EDITAR Y ELIMINAR
function editItem(itemName) {
    alert(`Editar: ${itemName}`);
}

function deleteItem(itemName) {
    if (confirm(`¿Estás seguro de que deseas eliminar ${itemName}?`)) {
        alert(`${itemName} ha sido eliminado correctamente.`);
    }
}

// ELIMINACIÓN REAL DE FILA
function eliminarFila(boton, itemName) {
    if (!confirm(`¿Estás seguro de que deseas eliminar ${itemName}? Esta acción no se puede deshacer.`)) return;
    const fila = boton.closest('tr');
    if (fila) {
        fila.style.opacity = '0.4';
        setTimeout(() => fila.remove(), 150);
    }
    alert(`${itemName} fue eliminado.`);
}

// PONER / QUITAR UN PRODUCTO EN DESCUENTO
function toggleDescuento(itemName, estaEnDescuento) {
    if (estaEnDescuento) {
        if (confirm(`¿Quitar el descuento de ${itemName}?`)) {
            alert(`${itemName} ya no está en descuento.`);
        }
    } else {
        alert(`Se abriría un formulario para elegir la promoción y el % a aplicar a ${itemName}.`);
    }
}

// REGISTRAR NUEVA COMPRA A PROVEEDOR
let compraCounter = 2;
function toggleCompraForm() {
    const form = document.getElementById('compraForm');
    if (form) form.style.display = (form.style.display === 'none' || !form.style.display) ? 'block' : 'none';
}
function registrarCompra() {
    const proveedor = document.getElementById('compraProveedor').value;
    const producto = document.getElementById('compraProducto').value.trim();
    const cantidad = parseInt(document.getElementById('compraCantidad').value);
    const precio = parseFloat(document.getElementById('compraPrecio').value);

    if (!producto || !cantidad || cantidad <= 0 || !precio || precio <= 0) {
        alert('Completa el producto, la cantidad y el precio de compra.');
        return;
    }

    const total = cantidad * precio;
    const ahora = new Date();
    const fecha = ahora.toISOString().slice(0, 19).replace('T', ' ');
    compraCounter++;

    const tbody = document.getElementById('comprasTbody');
    if (tbody) {
        const fila = document.createElement('tr');
        fila.innerHTML = `
            <td>${compraCounter}</td>
            <td>${proveedor}</td>
            <td>${fecha}</td>
            <td>${producto}</td>
            <td>${cantidad}</td>
            <td>$${precio.toLocaleString('es-CO')},00</td>
            <td><strong>$${total.toLocaleString('es-CO')},00</strong></td>
        `;
        tbody.appendChild(fila);
    }

    alert(`✅ Compra #${compraCounter} registrada.`);
    document.getElementById('compraProducto').value = '';
    document.getElementById('compraCantidad').value = '50';
    document.getElementById('compraPrecio').value = '1000';
    toggleCompraForm();
}

// INICIALIZACIÓN DE LA GRÁFICA DE VENTAS
let salesChartInstance = null;

function renderSalesChart() {
    const canvas = document.getElementById('salesChart');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    
    if (salesChartInstance) {
        salesChartInstance.destroy();
    }

    salesChartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ['Julio 01', 'Julio 02', 'Julio 03', 'Agosto 02', 'Agosto 03', 'Agosto 04'],
            datasets: [{
                label: 'Ventas Totales ($)',
                data: [22950, 21600, 36000, 15000, 4500, 9000],
                backgroundColor: '#3b82f6',
                borderRadius: 5
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'top' },
                title: { display: true, text: 'Ventas Recientes de Colorín Papelín' }
            }
        }
    });
}

// ACTIVAR / DESACTIVAR UNA PROMOCION
const DESCUENTOS_ESTADO_KEY = "colorinPapelin_estadoDescuentos";
const DESCUENTOS_ESTADO_DEFAULT = { 0: "Activo", 1: "Inactivo", 2: "Activo", 3: "Inactivo" };
const DESCUENTOS_NOMBRES = { 0: "Sin descuento", 1: "Regreso a Clases", 2: "Cliente Frecuente", 3: "Fin de Año" };

function getEstadoDescuentos() {
    try {
        const guardado = JSON.parse(localStorage.getItem(DESCUENTOS_ESTADO_KEY));
        return guardado || Object.assign({}, DESCUENTOS_ESTADO_DEFAULT);
    } catch (e) {
        return Object.assign({}, DESCUENTOS_ESTADO_DEFAULT);
    }
}

function pintarEstadoDescuento(id, estado) {
    const badge = document.getElementById('descuento-badge-' + id);
    const btn = document.getElementById('descuento-toggle-' + id);
    if (!badge || !btn) return;
    badge.innerText = estado;
    badge.className = "badge " + (estado === "Activo" ? "success" : "danger");
    btn.innerText = estado === "Activo" ? "Desactivar" : "Activar";
    btn.classList.toggle("btn-primary", estado !== "Activo");
}

function initDescuentos() {
    const estados = getEstadoDescuentos();
    Object.keys(estados).forEach(function(id) { pintarEstadoDescuento(id, estados[id]); });
}

function toggleEstadoDescuento(id) {
    const estados = getEstadoDescuentos();
    const nuevoEstado = estados[id] === "Activo" ? "Inactivo" : "Activo";
    estados[id] = nuevoEstado;
    localStorage.setItem(DESCUENTOS_ESTADO_KEY, JSON.stringify(estados));
    pintarEstadoDescuento(id, nuevoEstado);
    alert('"' + DESCUENTOS_NOMBRES[id] + '" ahora esta ' + nuevoEstado + '.');
}

// AÑADIR PRODUCTO NUEVO
let productoCounter = 13;
function toggleProductoForm() {
    const form = document.getElementById('productoForm');
    if (form) form.style.display = (form.style.display === 'none' || !form.style.display) ? 'block' : 'none';
}
function registrarProducto() {
    const nombre = document.getElementById('prodNombre').value.trim();
    const proveedor = document.getElementById('prodProveedor').value;
    const categoria = document.getElementById('prodCategoria').value;
    const pCompra = parseFloat(document.getElementById('prodPrecioCompra').value);
    const pVenta = parseFloat(document.getElementById('prodPrecioVenta').value);
    const stock = parseInt(document.getElementById('prodStock').value);
    const stockMin = parseInt(document.getElementById('prodStockMinimo').value);

    if (!nombre || !pCompra || !pVenta) {
        alert('Completa al menos el nombre, precio de compra y precio de venta.');
        return;
    }

    productoCounter++;
    const tbody = document.getElementById('productosTbody');
    if (tbody) {
        const fila = document.createElement('tr');
        const stockBadgeClass = stock <= 0 ? 'danger' : (stock <= stockMin ? 'warning' : 'success');
        fila.innerHTML = `
            <td>${productoCounter}</td>
            <td>${nombre}</td>
            <td>${proveedor}</td>
            <td>$${pCompra.toLocaleString('es-CO')}</td>
            <td>$${pVenta.toLocaleString('es-CO')}</td>
            <td><span class="badge secondary">Sin descuento</span></td>
            <td><span class="badge ${stockBadgeClass}">${stock}</span></td>
            <td>${stockMin}</td>
            <td>${categoria}</td>
            <td>
                <button class="btn btn-sm btn-edit" onclick="editItem('Producto #${productoCounter}')">Editar</button>
                <button class="btn btn-sm btn-delete" onclick="eliminarFila(this, 'Producto #${productoCounter}')">Eliminar</button>
                <button class="btn btn-sm btn-primary" onclick="toggleDescuento('Producto #${productoCounter}', false)">Poner en descuento</button>
            </td>
        `;
        tbody.appendChild(fila);
    }

    alert(`✅ Producto "${nombre}" agregado al catálogo.`);
    document.getElementById('prodNombre').value = '';
    toggleProductoForm();
}

// AÑADIR USUARIO NUEVO
let usuarioCounter = 6;
function toggleUsuarioForm() {
    const form = document.getElementById('usuarioForm');
    if (form) form.style.display = (form.style.display === 'none' || !form.style.display) ? 'block' : 'none';
}
function registrarUsuario() {
    const nombre = document.getElementById('userNombre').value.trim();
    const apellido = document.getElementById('userApellido').value.trim();
    const correo = document.getElementById('userCorreo').value.trim();
    const telefono = document.getElementById('userTelefono').value.trim();
    const direccion = document.getElementById('userDireccion').value.trim();
    const rol = document.getElementById('userRol').value;

    if (!nombre || !apellido || !correo) {
        alert('Completa al menos nombre, apellido y correo.');
        return;
    }

    usuarioCounter++;
    const badgeClass = rol === 'Administrador' ? 'warning' : (rol === 'Empleado' ? 'secondary' : 'primary');
    const tbody = document.getElementById('usuariosTbody');
    if (tbody) {
        const fila = document.createElement('tr');
        fila.innerHTML = `
            <td>${usuarioCounter}</td>
            <td>${nombre}</td>
            <td>${apellido}</td>
            <td>${correo}</td>
            <td>${telefono || '—'}</td>
            <td>—</td>
            <td>${direccion || '—'}</td>
            <td><span class="badge ${badgeClass}" id="rol-usuario-${usuarioCounter}">${rol}</span></td>
            <td>
                <button class="btn btn-sm btn-edit" onclick="editItem('Usuario #${usuarioCounter}')">Editar</button>
                <button class="btn btn-sm" onclick="abrirCambioRol(${usuarioCounter}, '${nombre} ${apellido}')">Cambiar rol</button>
                <button class="btn btn-sm btn-delete" onclick="eliminarFila(this, 'Usuario #${usuarioCounter}')">Eliminar</button>
            </td>
        `;
        tbody.appendChild(fila);
    }

    alert(`✅ Usuario "${nombre} ${apellido}" creado.`);
    document.getElementById('userNombre').value = '';
    document.getElementById('userApellido').value = '';
    document.getElementById('userCorreo').value = '';
    toggleUsuarioForm();
}

// AÑADIR CATEGORIA
let categoriaCounter = 3;
function toggleCategoriaForm() {
    const form = document.getElementById('categoriaForm');
    if (form) form.style.display = (form.style.display === 'none' || !form.style.display) ? 'block' : 'none';
}
function registrarCategoria() {
    const nombre = document.getElementById('catNombre').value.trim();
    const descripcion = document.getElementById('catDescripcion').value.trim();
    if (!nombre) { alert('Escribe el nombre de la categoría.'); return; }
    categoriaCounter++;
    const tbody = document.getElementById('categoriasTbody');
    if (tbody) {
        const fila = document.createElement('tr');
        fila.innerHTML = `
            <td>${categoriaCounter}</td>
            <td>${nombre}</td>
            <td>${descripcion || '—'}</td>
            <td>
                <button class="btn btn-sm btn-edit" onclick="editItem('Categoría #${categoriaCounter}')">Editar</button>
                <button class="btn btn-sm btn-delete" onclick="eliminarFila(this, 'Categoría #${categoriaCounter}')">Eliminar</button>
            </td>
        `;
        tbody.appendChild(fila);
    }
    alert(`✅ Categoría "${nombre}" agregada.`);
    document.getElementById('catNombre').value = '';
    document.getElementById('catDescripcion').value = '';
    toggleCategoriaForm();
}

// AÑADIR PROVEEDOR
let proveedorCounter = 3;
function toggleProveedorForm() {
    const form = document.getElementById('proveedorForm');
    if (form) form.style.display = (form.style.display === 'none' || !form.style.display) ? 'block' : 'none';
}
function registrarProveedor() {
    const nombre = document.getElementById('provNombre').value.trim();
    const telefono = document.getElementById('provTelefono').value.trim();
    const correo = document.getElementById('provCorreo').value.trim();
    const direccion = document.getElementById('provDireccion').value.trim();
    if (!nombre) { alert('Escribe el nombre del proveedor.'); return; }
    proveedorCounter++;
    const tbody = document.getElementById('proveedoresTbody');
    if (tbody) {
        const fila = document.createElement('tr');
        fila.innerHTML = `
            <td>${proveedorCounter}</td>
            <td>${nombre}</td>
            <td>${telefono || '—'}</td>
            <td>${correo || '—'}</td>
            <td>${direccion || '—'}</td>
            <td>
                <button class="btn btn-sm btn-edit" onclick="editItem('Proveedor #${proveedorCounter}')">Editar</button>
                <button class="btn btn-sm btn-delete" onclick="eliminarFila(this, 'Proveedor #${proveedorCounter}')">Eliminar</button>
            </td>
        `;
        tbody.appendChild(fila);
    }
    alert(`✅ Proveedor "${nombre}" agregado.`);
    document.getElementById('provNombre').value = '';
    document.getElementById('provTelefono').value = '';
    document.getElementById('provCorreo').value = '';
    document.getElementById('provDireccion').value = '';
    toggleProveedorForm();
}

// AÑADIR METODO DE PAGO
let metodoCounter = 2;
function toggleMetodoForm() {
    const form = document.getElementById('metodoForm');
    if (form) form.style.display = (form.style.display === 'none' || !form.style.display) ? 'block' : 'none';
}
function registrarMetodo() {
    const nombre = document.getElementById('metNombre').value.trim();
    if (!nombre) { alert('Escribe el nombre del método de pago.'); return; }
    metodoCounter++;
    const tbody = document.getElementById('metodosTbody');
    if (tbody) {
        const fila = document.createElement('tr');
        fila.innerHTML = `
            <td>${metodoCounter}</td>
            <td>${nombre}</td>
            <td>
                <button class="btn btn-sm btn-edit" onclick="editItem('Método de Pago #${metodoCounter}')">Editar</button>
                <button class="btn btn-sm btn-delete" onclick="eliminarFila(this, 'Método de Pago #${metodoCounter}')">Eliminar</button>
            </td>
        `;
        tbody.appendChild(fila);
    }
    alert(`✅ Método "${nombre}" agregado.`);
    document.getElementById('metNombre').value = '';
    toggleMetodoForm();
}

// AÑADIR PROMOCION DE DESCUENTO
let descuentoPromoCounter = 3;
function toggleDescuentoPromoForm() {
    const form = document.getElementById('descuentoPromoForm');
    if (form) form.style.display = (form.style.display === 'none' || !form.style.display) ? 'block' : 'none';
}
function registrarDescuentoPromo() {
    const nombre = document.getElementById('descNombre').value.trim();
    const porcentaje = parseFloat(document.getElementById('descPorcentaje').value);
    const inicio = document.getElementById('descInicio').value;
    const fin = document.getElementById('descFin').value;
    if (!nombre || !porcentaje) { alert('Completa el nombre y el porcentaje.'); return; }
    descuentoPromoCounter++;
    const id = descuentoPromoCounter;
    const tbody = document.getElementById('descuentosTbody');
    if (tbody) {
        const fila = document.createElement('tr');
        fila.id = 'descuento-row-' + id;
        fila.innerHTML = `
            <td>${id}</td>
            <td>${nombre}</td>
            <td>${inicio}</td>
            <td>${fin}</td>
            <td>${porcentaje.toFixed(2)}%</td>
            <td><span class="badge danger" id="descuento-badge-${id}">Inactivo</span></td>
            <td>
                <button class="btn btn-sm btn-edit" onclick="editItem('Descuento #${id}')">Editar</button>
                <button class="btn btn-sm btn-delete" onclick="eliminarFila(this, 'Descuento #${id}')">Eliminar</button>
                <button class="btn btn-sm btn-primary" id="descuento-toggle-${id}" onclick="toggleEstadoDescuento(${id})">Activar</button>
            </td>
        `;
        tbody.appendChild(fila);
    }
    DESCUENTOS_NOMBRES[id] = nombre;

    alert(`✅ Promoción "${nombre}" (-${porcentaje}%) creada.`);
    document.getElementById('descNombre').value = '';
    toggleDescuentoPromoForm();
}

// AÑADIR ROL
let rolCounter = 3;
function toggleRolForm() {
    const form = document.getElementById('rolForm');
    if (form) form.style.display = (form.style.display === 'none' || !form.style.display) ? 'block' : 'none';
}
function registrarRol() {
    const nombre = document.getElementById('rolNombre').value.trim();
    if (!nombre) { alert('Escribe el nombre del rol.'); return; }
    rolCounter++;
    const tbody = document.getElementById('rolesTbody');
    if (tbody) {
        const fila = document.createElement('tr');
        fila.innerHTML = `
            <td>${rolCounter}</td>
            <td><span class="badge secondary">${nombre}</span></td>
            <td>
                <button class="btn btn-sm btn-edit" onclick="editItem('Rol #${rolCounter}')">Editar</button>
            </td>
        `;
        tbody.appendChild(fila);
    }
    alert(`✅ Rol "${nombre}" agregado.`);
    document.getElementById('rolNombre').value = '';
    toggleRolForm();
}

// CAMBIAR ROL DE UN USUARIO
let usuarioEnCambioRol = null;
function abrirCambioRol(idUsuario, nombreUsuario) {
    usuarioEnCambioRol = idUsuario;
    document.getElementById('rolModalTitulo').innerText = 'Cambiar rol: ' + nombreUsuario;
    const badge = document.getElementById('rol-usuario-' + idUsuario);
    if (badge) document.getElementById('rolModalSelect').value = badge.innerText.trim();
    document.getElementById('modal-rol-usuario').style.display = 'flex';
}
function cerrarCambioRol() {
    document.getElementById('modal-rol-usuario').style.display = 'none';
    usuarioEnCambioRol = null;
}
function confirmarCambioRol() {
    const nuevoRol = document.getElementById('rolModalSelect').value;
    const badge = document.getElementById('rol-usuario-' + usuarioEnCambioRol);
    if (badge) {
        badge.innerText = nuevoRol;
        badge.className = 'badge ' + (nuevoRol === 'Administrador' ? 'warning' : (nuevoRol === 'Empleado' ? 'secondary' : 'primary'));
    }
    alert(`✅ El usuario ahora tiene el rol: ${nuevoRol}.`);
    cerrarCambioRol();
}
