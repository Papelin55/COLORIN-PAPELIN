const slider = document.getElementById('heroSlider');
    const prevBtn = document.getElementById('prevSlide');
    const nextBtn = document.getElementById('nextSlide');
    const dots = document.querySelectorAll('.dot');
    
    let currentIndex = 0;
    const totalSlides = 2;

    function updateSlider(index) {
        currentIndex = index;
        if (currentIndex < 0) currentIndex = totalSlides - 1;
        if (currentIndex >= totalSlides) currentIndex = 0;
        
        // Mueve el carrusel el equivalente al porcentaje exacto de la vista (50% ya que mide 200%)
        slider.style.transform = `translateX(-${currentIndex * 50}%)`;
        
        // Actualizar puntos activos
        dots.forEach(dot => dot.classList.remove('active'));
        dots[currentIndex].classList.add('active');
    }

    nextBtn.addEventListener('click', () => updateSlider(currentIndex + 1));
    prevBtn.addEventListener('click', () => updateSlider(currentIndex - 1));

    dots.forEach(dot => {
        dot.addEventListener('click', (e) => {
            const targetIndex = parseInt(e.target.dataset.index);
            updateSlider(targetIndex);
        });
    });

    // Desplazamiento automático cada 6 segundos
    setInterval(() => {
        updateSlider(currentIndex + 1);
    }, 6000);

// ---------- PROMOCIONES: descuentos + kits ----------
function renderPromos() {
    const descGrid = document.getElementById("descuentosGrid");
    if (descGrid) {
        descGrid.innerHTML = DESCUENTOS.filter(d => d.id !== 0).map(d => `
            <div class="descuento-card">
                <div class="descuento-icon"><i class="${d.icon}"></i></div>
                <div style="flex:1;">
                    <h4>${escapeHtml(d.nombre)}</h4>
                    <div style="font-size:0.78rem; color:#a08a72;">${d.inicio} → ${d.fin}</div>
                </div>
                <div style="text-align:right;">
                    <div class="descuento-pct">${d.porcentaje}%</div>
                    <span class="status-pill ${d.estado === 'Activo' ? 'status-ok' : 'status-bad'}" style="font-size:0.68rem;">${d.estado}</span>
                </div>
            </div>
        `).join("");
    }

    const productosDescGrid = document.getElementById("productosDescuentoGrid");
    if (productosDescGrid) {
        const enDescuento = catalog.filter(p => descuentoActivo(p));
        if (!enDescuento.length) {
            productosDescGrid.innerHTML = `<div style="grid-column:1/-1; color:#a08a72;">Por ahora no hay productos individuales en descuento.</div>`;
        } else {
            renderGrid("productosDescuentoGrid", enDescuento);
        }
    }

    const kitsGrid = document.getElementById("kitsGrid");
    if (kitsGrid) {
        kitsGrid.innerHTML = KITS.map(kit => {
            const original = kitPrecioOriginal(kit);
            const final = kitPrecioFinal(kit);
            const nombres = kit.items.map(id => catalog.find(p => p.id === id)?.name).filter(Boolean).join(" + ");
            return `
            <div class="product-card">
                <div class="product-img"><i class="${kit.icon}" style="font-size:2.8rem;"></i></div>
                <span class="badge-stock badge-bajo">-${Math.round(kit.descuento * 100)}%</span>
                <h4>${escapeHtml(kit.nombre)}</h4>
                <p style="font-size:0.78rem; color:#a08a72; margin:2px 0 6px;">${escapeHtml(nombres)}</p>
                <div class="price">${formatCOP(final)} <span style="font-size:0.75rem; color:#c9b7a5; text-decoration:line-through; font-weight:400;">${formatCOP(original)}</span></div>
                <button class="btn-card" onclick="addKitToCart('${kit.id}')"><i class="fas fa-cart-plus"></i> Añadir kit</button>
            </div>`;
        }).join("");
    }
}

// ---------- FAQ (Contacto) ----------
const FAQ_DATA = [
    { q: "¿Hacen envíos a domicilio?", a: "Sí, hacemos envíos dentro de Soacha y Ciudad Verde. El costo de envío se calcula en el carrito según tu compra." },
    { q: "¿Qué métodos de pago aceptan?", a: "Aceptamos Efectivo (contra entrega) y Nequi. Muy pronto tarjeta débito/crédito." },
    { q: "¿Hacen fotocopias e impresiones?", a: "Sí, contamos con servicio de fotocopiado, impresión y plastificado directamente en tienda." },
    { q: "¿Puedo aplicar a las promociones vigentes?", a: "Sí, revisa la sección de Promociones: ahí verás qué productos tienen descuento activo en este momento." }
];
function renderFaq() {
    const container = document.getElementById("faqList");
    if (!container) return;
    container.innerHTML = FAQ_DATA.map((item, idx) => `
        <div class="faq-item" id="faq-${idx}">
            <div class="faq-question" onclick="toggleFaq(${idx})">
                <span>${escapeHtml(item.q)}</span>
                <i class="fas fa-chevron-down"></i>
            </div>
            <div class="faq-answer"><p>${escapeHtml(item.a)}</p></div>
        </div>
    `).join("");
}
function toggleFaq(idx) {
    document.getElementById("faq-" + idx).classList.toggle("open");
}

document.addEventListener("catalogoListo", () => {
    renderPromos();
    renderFaq();
});
