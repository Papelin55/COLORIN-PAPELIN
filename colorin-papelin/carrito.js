function iconFor(id) {
    const p = catalog.find(x => x.id === id);
    return p ? p.icon : "fas fa-box";
}

function renderCart() {
    const cart = getCart();
    const layout = document.getElementById("cartLayout");
    const session = getSession();

    if (cart.length === 0) {
        layout.innerHTML = `
            <div class="cart-items" style="flex:1;">
                <div class="empty-cart">
                    <i class="fas fa-basket-shopping"></i>
                    <h3>Tu carrito está vacío</h3>
                    <p>Explora el catálogo y añade tus favoritos ✨</p>
                    <button class="btn-primary" style="margin-top:1.2rem;" onclick="window.location.href='productos.html'">Ir al catálogo</button>
                </div>
            </div>`;
        return;
    }

    const itemsHtml = cart.map(item => {
        const p = catalog.find(prod => prod.id === item.id);
        if (!p) return "";
        const d = descuentoActivo(p);
        const precio = precioFinal(p);
        return `
        <div class="cart-item-row">
            <div class="cart-item-icon"><i class="${p.icon}"></i></div>
            <div class="cart-item-info">
                <h4>${escapeHtml(p.name)}</h4>
                <div class="unit-price">
                    ${formatCOP(precio)} c/u
                    ${d ? `<span class="price-original">${formatCOP(p.price)}</span> <span class="badge-stock badge-descuento" style="margin:0 0 0 6px;">-${d.porcentaje}%</span>` : ""}
                </div>
            </div>
            <div class="qty-control">
                <button onclick="changeQty(${p.id}, -1)">−</button>
                <span>${item.cantidad}</span>
                <button onclick="changeQty(${p.id}, 1)">+</button>
            </div>
            <div class="cart-item-total">${formatCOP(precio * item.cantidad)}</div>
            <button class="remove-item-btn" onclick="removeItem(${p.id})"><i class="fas fa-trash"></i></button>
        </div>`;
    }).join("");

    const subtotal = cartSubtotal();
    const ahorro = cartAhorro();
    const envio = subtotal > 0 && subtotal < 50000 ? 5000 : 0;
    const total = subtotal + envio;

    layout.innerHTML = `
        <div class="cart-items">${itemsHtml}</div>
        <div class="cart-summary">
            <h3>Resumen del pedido</h3>
            <div class="summary-row"><span>Subtotal</span><span>${formatCOP(subtotal)}</span></div>
            ${ahorro > 0 ? `<div class="summary-row"><span>Ahorro por descuentos</span><span style="color:#237a4b;">-${formatCOP(ahorro)}</span></div>` : ""}
            <div class="summary-row"><span>Envío</span><span>${envio === 0 ? "Gratis" : formatCOP(envio)}</span></div>
            <div class="summary-row total"><span>Total</span><span>${formatCOP(total)}</span></div>

            <p style="font-size:0.78rem; color:#a08a72; margin:1rem 0; line-height:1.5;">
                <i class="fas fa-circle-info"></i> Se enviará a la dirección y teléfono guardados en tu perfil
                ${session ? ` (<strong>${escapeHtml(session.nombre)}</strong>)` : ""}.
                ${session ? "" : `<a href="login-v2.html" style="color:#cf8a5c; font-weight:600;">Inicia sesión</a> para continuar.`}
            </p>

            <div class="form-field">
                <label>Método de pago</label>
                <select id="metodoPago" onchange="actualizarPanelPago()">
                    <option value="1">Efectivo (contra entrega)</option>
                    <option value="2">Nequi</option>
                </select>
            </div>

            <div id="panelPago"></div>

            <button class="btn-primary" style="width:100%; justify-content:center;" onclick="confirmarPedido()">
                Confirmar pedido <i class="fas fa-check"></i>
            </button>
        </div>
    `;
    actualizarPanelPago();
}

function actualizarPanelPago() {
    const metodo = document.getElementById("metodoPago")?.value;
    const panel = document.getElementById("panelPago");
    if (!panel) return;

    if (metodo === "2") {
        panel.innerHTML = `
            <div class="pago-nequi-box">
                <div class="pago-nequi-qr"><i class="fas fa-qrcode"></i></div>
                <div>
                    <p style="margin:0 0 4px; font-weight:700; color:#3a2c1f;">Envía el pago a: 300 456 7890</p>
                    <p style="margin:0; font-size:0.8rem; color:#7a6248;">Escanea el QR o transfiere desde tu app Nequi, luego sube el comprobante.</p>
                </div>
            </div>
            <div class="form-field">
                <label>Comprobante de pago (captura o PDF) *</label>
                <input type="file" id="comprobantePago" accept="image/*,.pdf">
                <p id="comprobanteNombre" style="font-size:0.78rem; color:#237a4b; margin-top:4px;"></p>
            </div>
        `;
        document.getElementById("comprobantePago").addEventListener("change", (e) => {
            const nombre = e.target.files[0]?.name;
            document.getElementById("comprobanteNombre").innerText = nombre ? `✅ ${nombre} listo para enviar` : "";
        });
    } else {
        panel.innerHTML = `
            <div class="pago-efectivo-box">
                <i class="fas fa-hand-holding-dollar"></i>
                <p style="margin:0; font-size:0.85rem; color:#7a6248;">
                    Pagas en efectivo cuando recibas tu pedido. El repartidor confirmará el pago y la entrega,
                    y tu pedido pasará a <strong>Entregado</strong> en "Mis pedidos".
                </p>
            </div>
        `;
    }
}

function changeQty(id, delta) {
    const cart = getCart();
    const item = cart.find(i => i.id === id);
    if (!item) return;
    updateCartQty(id, item.cantidad + delta);
    if (getCart().find(i => i.id === id)?.cantidad <= 0) removeFromCart(id);
    renderCart();
}
function removeItem(id) { removeFromCart(id); renderCart(); }

function confirmarPedido() {
    const session = getSession();
    if (!session) {
        alert("Debes iniciar sesión para confirmar tu pedido (así usamos la dirección y teléfono de tu perfil).");
        window.location.href = "login-v2.html";
        return;
    }
    const esNequi = document.getElementById("metodoPago").value == "2";
    const metodo = esNequi ? "Nequi" : "Efectivo (contra entrega)";

    if (esNequi) {
        const archivo = document.getElementById("comprobantePago")?.files[0];
        if (!archivo) {
            alert("Falta subir el comprobante de pago de Nequi para poder confirmar el pedido.");
            return;
        }
        alert(`✅ ¡Pedido confirmado, ${session.nombre}!\n\nMétodo de pago: Nequi\nComprobante: ${archivo.name}\nEstado: Pendiente de verificación por un empleado.\n\nEn este demo el archivo no se sube a ningún servidor; al conectar la base de datos se guardaría junto al pedido para que el equipo confirme el pago.`);
    } else {
        alert(`✅ ¡Pedido confirmado, ${session.nombre}!\n\nMétodo de pago: ${metodo}\nEnvío a la dirección registrada en tu perfil.\nEstado: Pendiente hasta que se confirme la entrega y el pago.\n\nEste es un demo de frontend, aún no está conectado a la base de datos.`);
    }
    setCart([]);
    renderCart();
}

document.addEventListener("catalogoListo", renderCart);
