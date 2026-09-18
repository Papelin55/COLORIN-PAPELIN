function badgeEstado(estado) {
        const map = { "Pagado": "status-ok", "Pendiente": "status-warn", "Entregado": "status-info", "Cancelado": "status-bad" };
        return `<span class="status-pill ${map[estado] || 'status-info'}">${estado}</span>`;
    }

    function renderDashboard() {
        const bajoStock = catalog.filter(p => p.stock > 0 && p.stock <= p.stockMinimo);
        const agotados = catalog.filter(p => p.stock <= 0);
        const pendientes = PEDIDOS_DEMO.filter(p => p.estado === "Pendiente").length;

        document.getElementById("statsGrid").innerHTML = `
            <div class="stat-card">
                <div class="stat-icon" style="background:#2660a4;"><i class="fas fa-receipt"></i></div>
                <div><div class="stat-value">${pendientes}</div><div class="stat-label">Pedidos pendientes</div></div>
            </div>
            <div class="stat-card">
                <div class="stat-icon" style="background:#a3720a;"><i class="fas fa-triangle-exclamation"></i></div>
                <div><div class="stat-value">${bajoStock.length}</div><div class="stat-label">Productos con stock bajo</div></div>
            </div>
            <div class="stat-card">
                <div class="stat-icon" style="background:#b3352a;"><i class="fas fa-ban"></i></div>
                <div><div class="stat-value">${agotados.length}</div><div class="stat-label">Productos agotados</div></div>
            </div>
        `;

        const alertItems = [...agotados, ...bajoStock];
        document.getElementById("alertsTable").innerHTML = alertItems.length ? `
            <thead><tr><th>Producto</th><th>Categoría</th><th>Stock actual</th><th>Estado</th></tr></thead>
            <tbody>${alertItems.map(p => `
                <tr>
                    <td>${escapeHtml(p.name)}</td>
                    <td>${CATEGORIAS[p.categoria]}</td>
                    <td>${p.stock}</td>
                    <td>${p.stock <= 0 ? '<span class="status-pill status-bad">Agotado</span>' : '<span class="status-pill status-warn">Stock bajo</span>'}</td>
                </tr>`).join("")}</tbody>
        ` : `<tbody><tr><td style="padding:1.6rem;">✅ Todo el inventario está en niveles saludables.</td></tr></tbody>`;
    }

    function renderPedidos() {
        document.getElementById("pedidosTable").innerHTML = `
            <thead><tr><th>Pedido</th><th>Cliente</th><th>Fecha</th><th>Pago</th><th>Estado</th><th>Total</th><th>Acción</th></tr></thead>
            <tbody>${PEDIDOS_DEMO.map(p => `
                <tr>
                    <td>#${p.id}</td>
                    <td>${escapeHtml(p.cliente)}</td>
                    <td>${p.fecha}</td>
                    <td>${METODOS_PAGO[p.metodo]}</td>
                    <td>${badgeEstado(p.estado)}</td>
                    <td>${formatCOP(p.total)}</td>
                    <td>${p.estado === "Pendiente" ? `<button class="btn-card" style="padding:0.4rem 1rem; font-size:0.8rem;" onclick="marcarEntregado(${p.id})">Marcar entregado</button>` : "—"}</td>
                </tr>`).join("")}</tbody>
        `;
    }
    function marcarEntregado(id) {
        alert(`Pedido #${id} marcado como entregado.\n\n(demo — esto actualizaría el campo id_estado en la tabla pedidos)`);
    }

    function renderInventarioLectura() {
        document.getElementById("inventoryTable").innerHTML = `
            <thead><tr><th>Producto</th><th>Categoría</th><th>Precio</th><th>Descuento</th><th>Stock</th><th>Estado</th><th>Acción</th></tr></thead>
            <tbody>${catalog.map(p => {
                const d = descuentoActivo(p);
                return `
                <tr>
                    <td>${escapeHtml(p.name)}</td>
                    <td>${CATEGORIAS[p.categoria]}</td>
                    <td>${d ? `${formatCOP(precioFinal(p))} <span class="price-original">${formatCOP(p.price)}</span>` : formatCOP(p.price)}</td>
                    <td>${d ? `<span class="status-pill status-ok">-${d.porcentaje}% ${escapeHtml(d.nombre)}</span>` : '<span style="color:#c9b7a5;">—</span>'}</td>
                    <td>${p.stock}</td>
                    <td>${p.stock <= 0 ? '<span class="status-pill status-bad">Agotado</span>' : (p.stock <= p.stockMinimo ? '<span class="status-pill status-warn">Stock bajo</span>' : '<span class="status-pill status-ok">Disponible</span>')}</td>
                    <td>${d
                        ? `<button class="btn-card" style="padding:0.35rem 0.9rem; font-size:0.78rem;" onclick="quitarDescuentoInventario(${p.id})">Quitar descuento</button>`
                        : `<button class="btn-card" style="padding:0.35rem 0.9rem; font-size:0.78rem;" onclick="ponerDescuentoInventario(${p.id})">Poner en descuento</button>`}
                    </td>
                </tr>`;
            }).join("")}</tbody>
        `;
    }

    let productoEnEdicion = null;
    function ponerDescuentoInventario(productoId) {
        productoEnEdicion = productoId;
        const producto = catalog.find(p => p.id === productoId);
        document.getElementById("descuentoModalTitulo").innerText = `Poner en descuento: ${producto.name}`;
        const select = document.getElementById("descuentoModalSelect");
        select.innerHTML = DESCUENTOS.map(d => `<option value="${d.id}">${escapeHtml(d.nombre)} (-${d.porcentaje}%${d.estado === "Inactivo" ? " · Inactivo" : ""})</option>`).join("");
        document.getElementById("descuentoOverlay").style.display = "flex";
    }
    function confirmarDescuentoModal() {
        const idDescuento = parseInt(document.getElementById("descuentoModalSelect").value);
        const promo = DESCUENTOS.find(d => d.id === idDescuento);
        setProductoDescuento(productoEnEdicion, idDescuento);
        cerrarDescuentoModal();
        renderInventarioLectura();
        if (promo.estado === "Inactivo") {
            alert(`⚠️ "${promo.nombre}" está marcada como Inactiva — el producto quedará listo, pero el precio no cambiará en la tienda hasta que la promoción se active.`);
        } else {
            alert(`✅ Producto puesto en descuento: ${promo.nombre} (-${promo.porcentaje}%). Ya se ve reflejado en la tienda.`);
        }
    }
    function cerrarDescuentoModal() {
        document.getElementById("descuentoOverlay").style.display = "none";
        productoEnEdicion = null;
    }
    function quitarDescuentoInventario(productoId) {
        quitarProductoDescuento(productoId);
        renderInventarioLectura();
    }

    function initVentaForm() {
        const select = document.getElementById("ventaProducto");
        select.innerHTML = catalog.filter(p => p.stock > 0).map(p => `<option value="${p.id}">${escapeHtml(p.name)} — ${formatCOP(p.price)}</option>`).join("");
        actualizarResumenVenta();
        select.addEventListener("change", actualizarResumenVenta);
        document.getElementById("ventaCantidad").addEventListener("input", actualizarResumenVenta);
    }
    function actualizarResumenVenta() {
        const id = parseInt(document.getElementById("ventaProducto").value);
        const cant = parseInt(document.getElementById("ventaCantidad").value) || 1;
        const p = catalog.find(prod => prod.id === id);
        if (!p) return;
        document.getElementById("ventaResumen").innerText = `Total a cobrar: ${formatCOP(p.price * cant)}`;
    }
    function registrarVenta() {
        const id = parseInt(document.getElementById("ventaProducto").value);
        const cant = parseInt(document.getElementById("ventaCantidad").value) || 1;
        const metodo = document.getElementById("ventaMetodo").value == "1" ? "Efectivo" : "Nequi";
        const p = catalog.find(prod => prod.id === id);
        if (!p || cant > p.stock) { alert("No hay stock suficiente para esa cantidad."); return; }
        alert(`✅ Venta registrada:\n${cant} x ${p.name}\nMétodo: ${metodo}\nTotal: ${formatCOP(p.price * cant)}\n\n(demo — esto crearía un registro en pedidos, detalles_pedido y ventas)`);
    }

    function switchTab(tab) {
        ["dashboard", "pedidos", "inventario", "venta"].forEach(t => {
            document.getElementById("tab-" + t).style.display = t === tab ? "block" : "none";
        });
        document.querySelectorAll(".nav-item[data-tab]").forEach(btn => {
            btn.classList.toggle("active", btn.getAttribute("data-tab") === tab);
        });
    }

    document.addEventListener("catalogoListo", () => {
        renderDashboard();
        renderPedidos();
        renderInventarioLectura();
        initVentaForm();
        document.querySelectorAll(".nav-item[data-tab]").forEach(btn => {
            btn.addEventListener("click", () => switchTab(btn.getAttribute("data-tab")));
        });
    });
