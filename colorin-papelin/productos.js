let currentCategory = "all";
let currentSearch = "";
let currentSort = "default";

function applyFilters() {
    let items = catalog.filter(p => {
        const matchCat = currentCategory === "all" || p.categoria === parseInt(currentCategory);
        const matchSearch = p.name.toLowerCase().includes(currentSearch) || p.desc.toLowerCase().includes(currentSearch);
        return matchCat && matchSearch;
    });
    items = [...items];
    if (currentSort === "price-asc") items.sort((a, b) => a.price - b.price);
    else if (currentSort === "price-desc") items.sort((a, b) => b.price - a.price);
    else if (currentSort === "name-asc") items.sort((a, b) => a.name.localeCompare(b.name));
    renderGrid("fullCatalogGrid", items);
}

document.addEventListener("catalogoListo", () => {
    document.querySelectorAll(".category-tab").forEach(tab => {
        tab.addEventListener("click", () => {
            document.querySelectorAll(".category-tab").forEach(t => t.classList.remove("active"));
            tab.classList.add("active");
            currentCategory = tab.getAttribute("data-cat");
            applyFilters();
        });
    });
    document.getElementById("searchInput").addEventListener("input", (e) => {
        currentSearch = e.target.value.toLowerCase();
        applyFilters();
    });
    document.getElementById("sortSelect").addEventListener("change", (e) => {
        currentSort = e.target.value;
        applyFilters();
    });
    applyFilters();
});
