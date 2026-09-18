function badgeEstado(estado) {
    const map = { "Pagado": "status-ok", "Pendiente": "status-warn", "Entregado": "status-info", "Cancelado": "status-bad" };
    return `<span class="status-pill ${map[estado] || 'status-info'}">${estado}</span>`;
}

function renderPedidos() {
    const container = document.getElementById("pedidosList");
    if (!MIS_PEDIDOS_DEMO.length) {
        container.innerHTML = `<div class="empty-cart"><i class="fas fa-box-open"></i><h3>Aún no tienes pedidos</h3><p>Cuando compres algo, aparecerá aquí.</p></div>`;
        return;
    }
    container.innerHTML = MIS_PEDIDOS_DEMO.map(p => {
        const total = pedidoTotal(p);
        const itemsHtml = p.items.map(i => {
            const prod = catalog.find(x => x.id === i.id);
            if (!prod) return "";
            return `
            <div class="pedido-item-row">
                <div class="pedido-item-icon"><i class="${prod.icon}"></i></div>
                <div class="pedido-item-name">${escapeHtml(prod.name)}</div>
                <div class="pedido-item-qty">x${i.cantidad}</div>
                <div class="pedido-item-price">${formatCOP(prod.price * i.cantidad)}</div>
            </div>`;
        }).join("");

        return `
        <div class="pedido-card" id="pedido-${p.id}">
            <div class="pedido-header" onclick="togglePedido(${p.id})">
                <div class="pedido-header-left">
                    <span class="pedido-id">Pedido #${p.id}</span>
                    <span class="pedido-fecha">${p.fecha}</span>
                    ${badgeEstado(p.estado)}
                </div>
                <div class="pedido-header-left">
                    <span class="pedido-total">${formatCOP(total)}</span>
                    <i class="fas fa-chevron-down pedido-toggle"></i>
                </div>
            </div>
            <div class="pedido-body">
                ${itemsHtml}
                <div class="pedido-meta">
                    <div><i class="fas fa-location-dot"></i> ${escapeHtml(p.direccion)}</div>
                    <div><i class="fas fa-phone"></i> ${p.telefono} · <i class="fas fa-credit-card"></i> ${METODOS_PAGO[p.metodo]}</div>
                </div>
                <div class="pedido-actions">
                    <button class="btn-card" onclick="reordenarPedido(${p.id})"><i class="fas fa-rotate-right"></i> Volver a pedir</button>
                    ${p.estado === "Pendiente" ? `<button class="btn-card" onclick="alert('Este pedido ya está en preparación. Te avisaremos cuando salga a reparto.')"><i class="fas fa-truck"></i> Rastrear pedido</button>` : ""}
                </div>
            </div>
        </div>`;
    }).join("");
}

function togglePedido(id) {
    document.getElementById("pedido-" + id).classList.toggle("open");
}

document.addEventListener("catalogoListo", renderPedidos);
