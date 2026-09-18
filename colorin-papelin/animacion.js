/* =========================================================
   COLORÍN PAPELÍN — Motor de datos y catálogo (demo frontend)
   Los datos reflejan la estructura real de la base de datos
   (tablas: categoria, producto, proovedores, metodo_pago)
   para que el equipo pueda mostrar el flujo completo sin backend.
   ========================================================= */

// ---------- CATEGORÍAS (igual a la tabla `categoria`) ----------
const CATEGORIAS = {
    1: "Útiles Escolares",
    2: "Papelería",
    3: "Oficina"
};

// ---------- PROVEEDORES (igual a la tabla `proovedores`) ----------
const PROVEEDORES = {
    1: "Papeles Nacionales S.A.S.",
    2: "Distribuidora Escolar Bogotá",
    3: "Suministros Capital S.A.S."
};

// ---------- MÉTODOS DE PAGO (igual a la tabla `metodo_pago`) ----------
const METODOS_PAGO = { 1: "Efectivo", 2: "Nequi" };

// ---------- SESIÓN (simulada en localStorage, sin backend) ----------
const SESSION_KEY = "colorinPapelin_sesion";
function setSession(nombre, rol) {
    localStorage.setItem(SESSION_KEY, JSON.stringify({ nombre, rol }));
}
function getSession() {
    try { return JSON.parse(localStorage.getItem(SESSION_KEY)); }
    catch (e) { return null; }
}
function clearSession() {
    localStorage.removeItem(SESSION_KEY);
    window.location.href = "login-v2.html";
}
function initAuthUI() {
    const session = getSession();
    document.querySelectorAll(".login-link[data-auth]").forEach(link => {
        if (session) {
            link.innerHTML = `<i class="fas fa-right-from-bracket"></i> Cerrar sesión (${escapeHtml(session.nombre)})`;
            link.removeAttribute("href");
            link.style.cursor = "pointer";
            link.onclick = (e) => { e.preventDefault(); clearSession(); };
        } else {
            link.innerHTML = `<i class="fas fa-user"></i> Iniciar sesión`;
            link.setAttribute("href", "login-v2.html");
            link.onclick = null;
        }
    });

    // Botón "Volver al panel" — solo visible si quien navega la tienda es Admin/Empleado
    const panelBtn = document.getElementById("volverPanelLink");
    if (panelBtn) {
        const rutaPanel = session && session.rol === "Administrador" ? "pag_admin/inicio.php"
            : session && session.rol === "Empleado" ? "empleado.html"
            : null;
        if (rutaPanel) {
            panelBtn.style.display = "flex";
            panelBtn.setAttribute("href", rutaPanel);
            panelBtn.innerHTML = `<i class="fas fa-arrow-left"></i> Volver al panel`;
        } else {
            panelBtn.style.display = "none";
        }
    }
}

// ---------- DESCUENTOS (igual a la tabla `descuentos`) ----------
const DESCUENTOS = [
    { id: 0, nombre: "Sin descuento", inicio: "2025-01-01", fin: "2030-12-31", estado: "Activo", porcentaje: 0, icon: "fas fa-ban" },
    { id: 1, nombre: "Regreso a Clases", inicio: "2026-01-10", fin: "2026-02-28", estado: "Inactivo", porcentaje: 10, icon: "fas fa-graduation-cap" },
    { id: 2, nombre: "Cliente Frecuente", inicio: "2026-03-01", fin: "2026-12-31", estado: "Activo", porcentaje: 15, icon: "fas fa-heart" },
    { id: 3, nombre: "Fin de Año", inicio: "2026-12-01", fin: "2026-12-31", estado: "Inactivo", porcentaje: 20, icon: "fas fa-champagne-glasses" }
];

// El admin puede activar/desactivar cada promoción desde pag_admin — se guarda aquí
// y esta tienda lo respeta al cargar cada página (misma idea que los descuentos por producto).
const DESCUENTOS_ESTADO_KEY = "colorinPapelin_estadoDescuentos";
function aplicarEstadoDescuentos() {
    try {
        const overrides = JSON.parse(localStorage.getItem(DESCUENTOS_ESTADO_KEY)) || {};
        DESCUENTOS.forEach(d => {
            if (overrides[d.id]) d.estado = overrides[d.id];
        });
    } catch (e) { /* nada guardado todavía, se usan los valores por defecto */ }
}
aplicarEstadoDescuentos();

// ---------- DESCUENTO APLICADO DIRECTO SOBRE EL PRODUCTO ----------
// (en vez de un código de cupón: el admin/empleado marca el producto como "en descuento"
// eligiendo una promoción de la tabla DESCUENTOS; se guarda en localStorage para que
// se refleje al instante en toda la tienda, sin recargar nada)
const PRODUCT_DISCOUNT_KEY = "colorinPapelin_descuentosProducto";
function getProductDiscountOverrides() {
    try { return JSON.parse(localStorage.getItem(PRODUCT_DISCOUNT_KEY)) || {}; }
    catch (e) { return {}; }
}
function aplicarOverridesDescuento() {
    const overrides = getProductDiscountOverrides();
    catalog.forEach(p => {
        if (Object.prototype.hasOwnProperty.call(overrides, p.id)) {
            p.idDescuento = overrides[p.id];
        }
    });
}
function setProductoDescuento(productoId, idDescuento) {
    const overrides = getProductDiscountOverrides();
    overrides[productoId] = idDescuento;
    localStorage.setItem(PRODUCT_DISCOUNT_KEY, JSON.stringify(overrides));
    aplicarOverridesDescuento();
}
function quitarProductoDescuento(productoId) { setProductoDescuento(productoId, null); }
function descuentoActivo(producto) {
    if (!producto.idDescuento) return null;
    const d = DESCUENTOS.find(x => x.id === producto.idDescuento);
    return (d && d.estado === "Activo") ? d : null;
}
function precioFinal(producto) {
    const d = descuentoActivo(producto);
    return d ? Math.round(producto.price * (1 - d.porcentaje / 100)) : producto.price;
}

// ---------- KITS / COMBOS (agrupan productos del catálogo con descuento) ----------
const KITS = [
    { id: "kit1", nombre: "Kit Escolar Básico", desc: "Todo lo esencial para empezar el año escolar", icon: "fas fa-graduation-cap", items: [1, 4, 3], descuento: 0.10 },
    { id: "kit2", nombre: "Kit Oficina Esencial", desc: "Organiza tu escritorio en un solo paquete", icon: "fas fa-briefcase", items: [7, 17, 9], descuento: 0.12 },
    { id: "kit3", nombre: "Kit Creativo", desc: "Para dibujar, colorear y dejar volar la imaginación", icon: "fas fa-palette", items: [3, 12, 6], descuento: 0.15 }
];
function kitPrecioOriginal(kit) {
    return kit.items.reduce((sum, id) => sum + (catalog.find(p => p.id === id)?.price || 0), 0);
}
function kitPrecioFinal(kit) {
    return Math.round(kitPrecioOriginal(kit) * (1 - kit.descuento));
}
function addKitToCart(kitId) {
    const kit = KITS.find(k => k.id === kitId);
    if (!kit) return;
    kit.items.forEach(id => addToCart(id, 1));
    alert(`🎁 "${kit.nombre}" añadido al carrito con ${Math.round(kit.descuento * 100)}% de descuento aplicado.`);
}

// ---------- CATÁLOGO (equivalente a la tabla `producto`) ----------
// ---------- CATÁLOGO: ahora se carga desde JSON Server, no es fijo ----------
// Antes: const catalog = [ ...18 productos escritos a mano... ];
// Ahora: se pide por fetch() a JSON Server (debe estar corriendo en :3000).
let catalog = [];

async function cargarCatalogo() {
    try {
        const respuesta = await fetch("http://localhost:3000/productos");
        catalog = await respuesta.json();
    } catch (error) {
        console.error("No se pudo conectar con JSON Server en :3000. ¿Está corriendo 'json-server --watch db.json --port 3000'?", error);
        catalog = [];
    }
    aplicarOverridesDescuento(); // aplica descuentos guardados en localStorage por el admin/empleado

    // Avisa a las demás páginas (productos.js, carrito.js, pedidos.js, etc.)
    // que el catálogo ya está listo para usarse.
    document.dispatchEvent(new Event("catalogoListo"));
}

cargarCatalogo();

// ---------- PEDIDOS RECIENTES DE DEMO (equivalente a `pedidos`) ----------
const PEDIDOS_DEMO = [
    { id: 31, cliente: "María González", fecha: "2026-08-03 09:12", metodo: 2, estado: "Pagado", total: 27300 },
    { id: 30, cliente: "Carlos Martínez", fecha: "2026-08-03 08:47", metodo: 1, estado: "Pendiente", total: 12500 },
    { id: 29, cliente: "Camilo Rojas", fecha: "2026-08-02 20:54", metodo: 1, estado: "Pagado", total: 4500 },
    { id: 28, cliente: "Felipe Torres", fecha: "2026-08-02 20:37", metodo: 2, estado: "Pagado", total: 1500 },
    { id: 27, cliente: "Camila Rojas", fecha: "2026-08-02 20:16", metodo: 1, estado: "Entregado", total: 7500 }
];

// ---------- MIS PEDIDOS (historial del cliente demo, con productos reales) ----------
const MIS_PEDIDOS_DEMO = [
    {
        id: 31, fecha: "2026-08-03 09:12", estado: "Pagado", metodo: 2,
        direccion: "Cra 5 # 12-34, Ciudad Verde, Soacha", telefono: "3118887766",
        items: [{ id: 1, cantidad: 2 }, { id: 12, cantidad: 1 }]
    },
    {
        id: 27, fecha: "2026-08-02 20:16", estado: "Entregado", metodo: 1,
        direccion: "Calle Principal #123, Soacha", telefono: "3118887766",
        items: [{ id: 6, cantidad: 1 }]
    },
    {
        id: 22, fecha: "2026-07-28 16:40", estado: "Pendiente", metodo: 1,
        direccion: "Cra 5 # 12-34, Ciudad Verde, Soacha", telefono: "3118887766",
        items: [{ id: 13, cantidad: 1 }, { id: 3, cantidad: 2 }]
    },
    {
        id: 19, fecha: "2026-07-15 11:05", estado: "Cancelado", metodo: 2,
        direccion: "Cra 5 # 12-34, Ciudad Verde, Soacha", telefono: "3118887766",
        items: [{ id: 16, cantidad: 1 }]
    }
];

// ---------- Utilidades ----------
function formatCOP(valor) {
    return "$" + Number(valor).toLocaleString("es-CO");
}
function escapeHtml(str) {
    return String(str).replace(/[&<>]/g, m => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[m]));
}

// ---------- CARRITO (persistente en localStorage, cruza entre páginas) ----------
const CART_KEY = "colorinPapelin_carrito";

function getCart() {
    try { return JSON.parse(localStorage.getItem(CART_KEY)) || []; }
    catch (e) { return []; }
}
function setCart(cart) {
    localStorage.setItem(CART_KEY, JSON.stringify(cart));
    updateCartBadge();
}
function addToCart(id, cantidad = 1) {
    const producto = catalog.find(p => p.id === id);
    if (!producto || producto.stock <= 0) return;
    const cart = getCart();
    const existente = cart.find(i => i.id === id);
    if (existente) {
        if (existente.cantidad < producto.stock) existente.cantidad += cantidad;
    } else {
        cart.push({ id, cantidad });
    }
    setCart(cart);
}
function removeFromCart(id) {
    setCart(getCart().filter(i => i.id !== id));
}
function updateCartQty(id, cantidad) {
    const cart = getCart();
    const item = cart.find(i => i.id === id);
    if (!item) return;
    const producto = catalog.find(p => p.id === id);
    item.cantidad = Math.max(1, Math.min(cantidad, producto ? producto.stock : cantidad));
    setCart(cart);
}
function cartCount() {
    return getCart().reduce((sum, i) => sum + i.cantidad, 0);
}
function cartSubtotal() {
    return getCart().reduce((sum, i) => {
        const p = catalog.find(prod => prod.id === i.id);
        return sum + (p ? precioFinal(p) * i.cantidad : 0);
    }, 0);
}
function cartAhorro() {
    return getCart().reduce((sum, i) => {
        const p = catalog.find(prod => prod.id === i.id);
        return sum + (p ? (p.price - precioFinal(p)) * i.cantidad : 0);
    }, 0);
}
function pedidoTotal(pedido) {
    return pedido.items.reduce((sum, i) => {
        const p = catalog.find(prod => prod.id === i.id);
        return sum + (p ? p.price * i.cantidad : 0);
    }, 0);
}
function reordenarPedido(pedidoId) {
    const pedido = MIS_PEDIDOS_DEMO.find(p => p.id === pedidoId);
    if (!pedido) return;
    pedido.items.forEach(i => addToCart(i.id, i.cantidad));
    window.location.href = "carrito.html";
}
function updateCartBadge() {
    document.querySelectorAll("#cartCount").forEach(el => {
        const n = cartCount();
        el.innerText = n + (n === 1 ? " artículo" : " artículos");
    });
}

// ---------- Render de tarjetas de producto ----------
function stockBadge(p) {
    if (p.stock <= 0) return '<span class="badge-stock badge-agotado">Agotado</span>';
    if (p.stock <= p.stockMinimo) return '<span class="badge-stock badge-bajo">¡Últimas unidades!</span>';
    return "";
}
function descuentoRibbon(p) {
    const d = descuentoActivo(p);
    if (!d) return "";
    return `<span class="badge-stock badge-descuento">-${d.porcentaje}% ${escapeHtml(d.nombre)}</span>`;
}
function priceHtml(p) {
    const d = descuentoActivo(p);
    if (!d) return `<div class="price">${formatCOP(p.price)}</div>`;
    return `<div class="price">${formatCOP(precioFinal(p))} <span class="price-original">${formatCOP(p.price)}</span></div>`;
}

function renderGrid(containerId, itemsArray) {
    const container = document.getElementById(containerId);
    if (!container) return;
    if (!itemsArray.length) {
        container.innerHTML = `<div style="grid-column:1/-1; text-align:center; padding:2rem;">🌸 No encontramos productos con ese filtro 🌸</div>`;
        return;
    }
    container.innerHTML = itemsArray.map(item => `
        <div class="product-card">
            <div class="product-img">
                <i class="${item.icon}" style="font-size: 2.8rem;"></i>
            </div>
            ${descuentoRibbon(item)}
            ${stockBadge(item)}
            <h4>${escapeHtml(item.name)}</h4>
            <p style="font-size:0.8rem; color:#a08a72; margin:2px 0 6px;">${escapeHtml(item.desc)}</p>
            ${priceHtml(item)}
            <button class="btn-card add-to-cart-btn" data-id="${item.id}" ${item.stock <= 0 ? "disabled" : ""}>
                <i class="fas fa-cart-plus"></i> ${item.stock <= 0 ? "Sin stock" : "Añadir"}
            </button>
        </div>
    `).join("");

    container.querySelectorAll(".add-to-cart-btn").forEach(btn => {
        btn.addEventListener("click", handleAddToCart);
    });
}

function handleAddToCart(e) {
    const btn = e.currentTarget;
    const id = parseInt(btn.getAttribute("data-id"));
    const producto = catalog.find(p => p.id === id);
    addToCart(id, 1);
    btn.innerHTML = '<i class="fas fa-check"></i> ¡Añadido!';
    setTimeout(() => {
        btn.innerHTML = '<i class="fas fa-cart-plus"></i> Añadir';
    }, 1000);
}

function initProductDisplays() {
    const featuredItems = catalog.filter(p => p.featured === true);
    renderGrid("featuredGrid", featuredItems);
    renderGrid("allProductsGrid", catalog);
    const libretasItems = catalog.filter(p => p.categoria === 1);
    renderGrid("notebooksGrid", libretasItems);
}

// ---------- Control de secciones (para index.html) ----------
function showSection(sectionId) {
    const sections = ["inicioSection", "productosSection", "libretasSection", "promosSection", "contactoSection"];
    sections.forEach(sec => {
        const el = document.getElementById(sec);
        if (el) el.style.display = "none";
    });
    const active = document.getElementById(sectionId);
    if (active) active.style.display = "block";

    const allBtns = document.querySelectorAll(".nav-item");
    allBtns.forEach(btn => btn.classList.remove("active"));
    const sectionMap = {
        inicioSection: "Inicio", productosSection: "Productos", libretasSection: "Libretas",
        promosSection: "Promociones", contactoSection: "Contacto"
    };
    const expected = sectionMap[sectionId];
    if (expected) {
        allBtns.forEach(btn => { if (btn.innerText.trim() === expected) btn.classList.add("active"); });
    }
}

function bindNavEvents() {
    const navMap = [
        { selector: '[data-section="inicio"]', section: "inicioSection" },
        { selector: '[data-section="productos"]', section: "productosSection" },
        { selector: '[data-section="libretas"]', section: "libretasSection" },
        { selector: '[data-section="promos"]', section: "promosSection" },
        { selector: '[data-section="contacto"]', section: "contactoSection" }
    ];
    navMap.forEach(item => {
        const btn = document.querySelector(item.selector);
        if (btn) btn.addEventListener("click", () => showSection(item.section));
    });
    const verMas = document.getElementById("verMasLink");
    if (verMas) verMas.addEventListener("click", () => showSection("productosSection"));
    const heroBtn = document.getElementById("heroBtn");
    if (heroBtn) heroBtn.addEventListener("click", () => showSection("productosSection"));
    const customBtn = document.getElementById("customBtn");
    if (customBtn) customBtn.addEventListener("click", () => alert("🎨 Escríbenos a personal@colorinpapelin.com y cuéntanos tu idea."));
    const promoBtn = document.getElementById("promoBtn");
    if (promoBtn) promoBtn.addEventListener("click", () => showSection("productosSection"));
    const contactBtn = document.getElementById("contactBtn");
    if (contactBtn) contactBtn.addEventListener("click", () => alert("📩 Gracias por contactar. Te responderemos con mucho color."));
    const cartIconDiv = document.getElementById("cartIcon");
    if (cartIconDiv) cartIconDiv.addEventListener("click", () => { window.location.href = "carrito.html"; });
}

// ---------- Sidebar toggle (compartido en todas las páginas) ----------
function initSidebarToggle() {
    const sidebar = document.getElementById("sidebar");
    const toggleBtn = document.getElementById("toggleSidebarBtn");
    const iconToggle = document.getElementById("toggleIcon");
    if (!sidebar || !toggleBtn) return;

    const isClosed = localStorage.getItem("sidebarClosed") === "true";
    if (isClosed) {
        sidebar.classList.add("closed");
        if (iconToggle) { iconToggle.classList.remove("fa-bars"); iconToggle.classList.add("fa-chevron-right"); }
    }
    toggleBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        sidebar.classList.toggle("closed");
        const nowClosed = sidebar.classList.contains("closed");
        localStorage.setItem("sidebarClosed", nowClosed);
        if (iconToggle) {
            iconToggle.classList.toggle("fa-bars", !nowClosed);
            iconToggle.classList.toggle("fa-chevron-right", nowClosed);
        }
    });
}

document.addEventListener("DOMContentLoaded", () => {
    bindNavEvents();
    initSidebarToggle();
    if (document.getElementById("inicioSection")) showSection("inicioSection");
    updateCartBadge();
    initAuthUI();
});

// initProductDisplays() necesita el catálogo ya cargado desde JSON Server,
// así que espera el evento catalogoListo en vez de DOMContentLoaded.
document.addEventListener("catalogoListo", () => {
    initProductDisplays();
});
