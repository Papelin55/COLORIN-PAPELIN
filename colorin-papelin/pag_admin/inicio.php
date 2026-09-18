<?php
// ==========================================
// CONFIGURACIÓN Y CONEXIÓN A LA BASE DE DATOS
// ==========================================
session_start();

$host    = 'localhost';
$db      = 'colorinpapelin_def';
$user    = 'root';
$pass    = '';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    die("Error de conexión a la base de datos: " . $e->getMessage());
}

$id_usuario_sesion = $_SESSION['id_usuario'] ?? 1;

// ==========================================
// DETECTAR PESTAÑA ACTIVA
// ==========================================
$tabActiva = $_REQUEST['tab'] ?? 'dashboard';

// ==========================================
// MANEJO DE PETICIONES POST (FORMULARIOS / CRUD)
// ==========================================
$mensaje_post = "";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    try {
        // ----- PRODUCTOS -----
        if ($action === 'crear_producto') {
            $stmt = $pdo->prepare("CALL sp_registrar_producto(:id_prov, :nombre, :desc, :p_compra, :p_venta, :img, :st_actual, :st_min, :id_cat)");
            $stmt->execute([
                ':id_prov'    => $_POST['id_proveedor'],
                ':nombre'     => $_POST['nombre'],
                ':desc'       => $_POST['descripcion'] ?? '',
                ':p_compra'   => $_POST['precio_compra'],
                ':p_venta'    => $_POST['precio_venta'],
                ':img'        => $_POST['url_imagen'] ?? 'default.jpg',
                ':st_actual'  => $_POST['stock_actual'],
                ':st_min'     => $_POST['stock_minimo'],
                ':id_cat'     => $_POST['id_categoria']
            ]);
            $mensaje_post = "Producto registrado con éxito.";
        } 
        elseif ($action === 'editar_producto') {
            $stmt = $pdo->prepare("UPDATE producto SET id_proveedor = ?, nombre = ?, descripcion = ?, precio_compra = ?, precio_venta = ?, stock_actual = ?, stock_minimo = ?, id_categoria = ? WHERE id_producto = ?");
            $stmt->execute([
                $_POST['id_proveedor'],
                $_POST['nombre'],
                $_POST['descripcion'] ?? '',
                $_POST['precio_compra'],
                $_POST['precio_venta'],
                $_POST['stock_actual'],
                $_POST['stock_minimo'],
                $_POST['id_categoria'],
                $_POST['id_producto']
            ]);
            $mensaje_post = "Producto actualizado correctamente.";
        }
        elseif ($action === 'eliminar_producto') {
            $stmt = $pdo->prepare("DELETE FROM producto WHERE id_producto = ?");
            $stmt->execute([$_POST['id_producto']]);
            $mensaje_post = "Producto eliminado.";
        }

        // ----- CATEGORÍAS -----
        elseif ($action === 'crear_categoria') {
            $stmt = $pdo->prepare("INSERT INTO categoria (nombre_categoria, descripcion) VALUES (?, ?)");
            $stmt->execute([$_POST['nombre_categoria'], $_POST['descripcion']]);
            $mensaje_post = "Categoría agregada.";
        }
        elseif ($action === 'editar_categoria') {
            $stmt = $pdo->prepare("UPDATE categoria SET nombre_categoria = ?, descripcion = ? WHERE id_categoria = ?");
            $stmt->execute([$_POST['nombre_categoria'], $_POST['descripcion'], $_POST['id_categoria']]);
            $mensaje_post = "Categoría actualizada.";
        }
        elseif ($action === 'eliminar_categoria') {
            $stmt = $pdo->prepare("DELETE FROM categoria WHERE id_categoria = ?");
            $stmt->execute([$_POST['id_categoria']]);
            $mensaje_post = "Categoría eliminada.";
        }

        // ----- PROVEEDORES -----
        elseif ($action === 'crear_proveedor') {
            $stmt = $pdo->prepare("INSERT INTO proovedores (nombre, telefono, correo, direccion) VALUES (?, ?, ?, ?)");
            $stmt->execute([$_POST['nombre'], $_POST['telefono'], $_POST['correo'], $_POST['direccion']]);
            $mensaje_post = "Proveedor guardado.";
        }
        elseif ($action === 'editar_proveedor') {
            $stmt = $pdo->prepare("UPDATE proovedores SET nombre = ?, telefono = ?, correo = ?, direccion = ? WHERE id_proovedores = ?");
            $stmt->execute([$_POST['nombre'], $_POST['telefono'], $_POST['correo'], $_POST['direccion'], $_POST['id_proveedor']]);
            $mensaje_post = "Proveedor actualizado.";
        }
        elseif ($action === 'eliminar_proveedor') {
            $stmt = $pdo->prepare("DELETE FROM proovedores WHERE id_proovedores = ?");
            $stmt->execute([$_POST['id_proveedor']]);
            $mensaje_post = "Proveedor eliminado.";
        }

        // ----- COMPRAS PROVEEDOR -----
        elseif ($action === 'registrar_compra') {
            $stmt = $pdo->prepare("CALL sp_registrar_compra(:id_usuario, :id_prov, :id_prod, :cant)");
            $stmt->execute([
                ':id_usuario' => $id_usuario_sesion,
                ':id_prov'    => $_POST['id_proveedor'],
                ':id_prod'    => $_POST['id_producto'],
                ':cant'       => $_POST['cantidad']
            ]);
            $mensaje_post = "Compra registrada y stock actualizado.";
        }

        // ----- DESCUENTOS -----
        elseif ($action === 'crear_descuento') {
            $stmt = $pdo->prepare("INSERT INTO descuentos (nombre, porcentaje, fecha_inicio, fecha_fin, estado) VALUES (?, ?, ?, ?, 'Inactivo')");
            $stmt->execute([$_POST['nombre'], $_POST['porcentaje'], $_POST['fecha_inicio'], $_POST['fecha_fin']]);
            $mensaje_post = "Descuento creado.";
        }
        elseif ($action === 'editar_descuento') {
            $stmt = $pdo->prepare("UPDATE descuentos SET nombre = ?, porcentaje = ?, fecha_inicio = ?, fecha_fin = ? WHERE id_descuento = ?");
            $stmt->execute([$_POST['nombre'], $_POST['porcentaje'], $_POST['fecha_inicio'], $_POST['fecha_fin'], $_POST['id_descuento']]);
            $mensaje_post = "Descuento actualizado.";
        }
        elseif ($action === 'toggle_estado_descuento') {
            $nuevo_estado = ($_POST['estado_actual'] === 'Activo') ? 'Inactivo' : 'Activo';
            $stmt = $pdo->prepare("UPDATE descuentos SET estado = ? WHERE id_descuento = ?");
            $stmt->execute([$nuevo_estado, $_POST['id_descuento']]);
            $mensaje_post = "Estado del descuento actualizado.";
        }

        // ----- USUARIOS -----
        elseif ($action === 'crear_usuario') {
            $stmt = $pdo->prepare("CALL sp_registrar_usuario(:nombre, :apellido, :correo, :pass, :tel, :tel2, :dir, :id_rol)");
            $stmt->execute([
                ':nombre'    => $_POST['nombre'],
                ':apellido'  => $_POST['apellido'],
                ':correo'    => $_POST['correo'],
                ':pass'      => password_hash($_POST['contraseña'] ?? '123456', PASSWORD_DEFAULT),
                ':tel'       => $_POST['telefono'],
                ':tel2'      => $_POST['telefono_secundario'] ?? null,
                ':dir'       => $_POST['direccion'],
                ':id_rol'    => $_POST['id_rol']
            ]);
            $mensaje_post = "Usuario creado.";
        }
        elseif ($action === 'editar_usuario') {
            $stmt = $pdo->prepare("UPDATE usuario SET nombre = ?, apellido = ?, correo = ?, telefono = ?, direccion = ?, id_rol = ? WHERE id_usuario = ?");
            $stmt->execute([
                $_POST['nombre'],
                $_POST['apellido'],
                $_POST['correo'],
                $_POST['telefono'],
                $_POST['direccion'],
                $_POST['id_rol'],
                $_POST['id_usuario']
            ]);
            $mensaje_post = "Usuario actualizado.";
        }
        elseif ($action === 'eliminar_usuario') {
            $stmt = $pdo->prepare("DELETE FROM usuario WHERE id_usuario = ?");
            $stmt->execute([$_POST['id_usuario']]);
            $mensaje_post = "Usuario eliminado.";
        }

        // ----- ROLES -----
        elseif ($action === 'crear_rol') {
            $stmt = $pdo->prepare("INSERT INTO roles (nombre_rol) VALUES (?)");
            $stmt->execute([$_POST['nombre_rol']]);
            $mensaje_post = "Nuevo rol creado.";
        }
        elseif ($action === 'editar_rol') {
            $stmt = $pdo->prepare("UPDATE roles SET nombre_rol = ? WHERE id_rol = ?");
            $stmt->execute([$_POST['nombre_rol'], $_POST['id_rol']]);
            $mensaje_post = "Rol actualizado.";
        }

        // ----- MÉTODOS DE PAGO -----
        elseif ($action === 'crear_metodo') {
            $stmt = $pdo->prepare("INSERT INTO metodo_pago (nombre) VALUES (?)");
            $stmt->execute([$_POST['nombre']]);
            $mensaje_post = "Método de pago agregado.";
        }
        elseif ($action === 'editar_metodo') {
            $stmt = $pdo->prepare("UPDATE metodo_pago SET nombre = ? WHERE id_metodo_pago = ?");
            $stmt->execute([$_POST['nombre'], $_POST['id_metodo_pago']]);
            $mensaje_post = "Método de pago actualizado.";
        }

    } catch (Exception $e) {
        $mensaje_post = "Error: " . $e->getMessage();
    }
}

// ==========================================
// CONSULTA DE DATOS PARA LAS TABLAS
// ==========================================

// Dashboard KPI
$dash_stmt = $pdo->query("CALL sp_dashboard()");
$kpis = $dash_stmt->fetch();
$dash_stmt->closeCursor();

// Stock Bajo Count
$stock_bajo_count = $pdo->query("SELECT COUNT(*) FROM vw_stock_bajo")->fetchColumn();

// Listas auxiliares
$categorias  = $pdo->query("SELECT * FROM categoria")->fetchAll();
$proveedores = $pdo->query("SELECT * FROM proovedores")->fetchAll();
$roles       = $pdo->query("SELECT * FROM roles")->fetchAll();

// Productos
$filtro_cat = $_GET['cat'] ?? '';
if ($filtro_cat != '') {
    $stmt_prod = $pdo->prepare("SELECT p.*, c.nombre_categoria, pr.nombre as proveedor FROM producto p JOIN categoria c ON p.id_categoria=c.id_categoria JOIN proovedores pr ON p.id_proveedor=pr.id_proovedores WHERE p.id_categoria = ?");
    $stmt_prod->execute([$filtro_cat]);
    $productos = $stmt_prod->fetchAll();
} else {
    $productos = $pdo->query("SELECT p.*, c.nombre_categoria, pr.nombre as proveedor FROM producto p JOIN categoria c ON p.id_categoria=c.id_categoria JOIN proovedores pr ON p.id_proveedor=pr.id_proovedores")->fetchAll();
}

// OTRAS TABLAS
$compras_lista   = $pdo->query("SELECT * FROM vw_compras ORDER BY fecha_compra DESC")->fetchAll();
$descuentos      = $pdo->query("SELECT * FROM descuentos")->fetchAll();
$metodos_pago    = $pdo->query("SELECT * FROM metodo_pago")->fetchAll();
$pedidos_lista   = $pdo->query("SELECT p.*, u.nombre, u.apellido, u.telefono, u.direccion FROM pedidos p JOIN usuario u ON p.id_usuario = u.id_usuario ORDER BY p.fecha_pedido DESC")->fetchAll();
$ventas_lista    = $pdo->query("SELECT * FROM vw_ventas ORDER BY fecha_venta DESC")->fetchAll();
$usuarios_lista  = $pdo->query("SELECT u.*, r.nombre_rol FROM usuario u JOIN roles r ON u.id_rol = r.id_rol")->fetchAll();
$logs_lista      = $pdo->query("SELECT * FROM logs ORDER BY fecha_movimiento DESC LIMIT 50")->fetchAll();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel de Administración - Colorín Papelín</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:opsz,wght@14..32,300;14..32,400;14..32,500;14..32,600;14..32,700&family=Playfair+Display:ital,wght@0,400;0,500;0,600;0,700;1,400&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="CSS.css">
    <style>
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0; left: 0;
            width: 100%; height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }
        .modal-content {
            background: #fff;
            padding: 24px;
            border-radius: 8px;
            max-width: 600px;
            width: 90%;
            max-height: 90vh;
            overflow-y: auto;
        }
        .btn-edit {
            background-color: #ffc107;
            color: #212529;
            border: none;
            padding: 4px 8px;
            border-radius: 4px;
            cursor: pointer;
        }
    </style>
</head>
<body>

    <aside class="sidebar">
        <div class="brand">
            <h2>Colorín Papelín</h2>
            <small>Sistema Admin</small>
        </div>
        <nav class="menu">
            <button class="nav-btn <?= ($tabActiva === 'dashboard') ? 'active' : '' ?>" onclick="switchTab('dashboard', this)">Dashboard</button>
            <button class="nav-btn <?= ($tabActiva === 'productos') ? 'active' : '' ?>" onclick="switchTab('productos', this)">Productos</button>
            <button class="nav-btn <?= ($tabActiva === 'categorias') ? 'active' : '' ?>" onclick="switchTab('categorias', this)">Categorías</button>
            <button class="nav-btn <?= ($tabActiva === 'proveedores') ? 'active' : '' ?>" onclick="switchTab('proveedores', this)">Proveedores</button>
            <button class="nav-btn <?= ($tabActiva === 'compras') ? 'active' : '' ?>" onclick="switchTab('compras', this)">Compras Proveedor</button>
            <button class="nav-btn <?= ($tabActiva === 'descuentos') ? 'active' : '' ?>" onclick="switchTab('descuentos', this)">Descuentos</button>
            <button class="nav-btn <?= ($tabActiva === 'metodospago') ? 'active' : '' ?>" onclick="switchTab('metodospago', this)">Métodos de Pago</button>
            <button class="nav-btn <?= ($tabActiva === 'pedidos') ? 'active' : '' ?>" onclick="switchTab('pedidos', this)">Pedidos Clientes</button>
            <button class="nav-btn <?= ($tabActiva === 'ventas') ? 'active' : '' ?>" onclick="switchTab('ventas', this)">Ventas</button>
            <button class="nav-btn <?= ($tabActiva === 'usuarios') ? 'active' : '' ?>" onclick="switchTab('usuarios', this)">Usuarios</button>
            <button class="nav-btn <?= ($tabActiva === 'roles') ? 'active' : '' ?>" onclick="switchTab('roles', this)">Roles</button>
            <button class="nav-btn <?= ($tabActiva === 'logs') ? 'active' : '' ?>" onclick="switchTab('logs', this)">Logs / Auditoría</button>
        </nav>
    </aside>

    <main class="main-content">

        <header class="top-header">
            <h1 id="section-title"><?= ucfirst($tabActiva) ?></h1>
            <div class="user-info" style="display:flex; align-items:center; gap:16px;">
                <span>Hola, <strong>Admin</strong></span>
                <button class="btn btn-sm btn-delete" onclick="window.location.href='../login-v2.html';">
                    Cerrar sesión
                </button>
            </div>
        </header>

        <?php if (!empty($mensaje_post)): ?>
            <div style="padding: 10px; margin-bottom: 15px; background-color: #d4edda; color: #155724; border-radius: 5px;">
                <?= htmlspecialchars($mensaje_post) ?>
            </div>
        <?php endif; ?>

        <!-- DASHBOARD -->
        <section id="tab-dashboard" class="tab-content <?= ($tabActiva === 'dashboard') ? 'active' : '' ?>">
            <div class="kpi-grid">
                <div class="kpi-card">
                    <h3>Ventas Totales</h3>
                    <p class="kpi-value">$<?= number_format($kpis['dinero_vendido'] ?? 0, 2, ',', '.') ?></p>
                </div>
                <div class="kpi-card">
                    <h3>Ventas Registradas</h3>
                    <p class="kpi-value"><?= $kpis['total_ventas'] ?? 0 ?></p>
                </div>
                <div class="kpi-card danger">
                    <h3>Stock Alerta / Agotado</h3>
                    <p class="kpi-value"><?= $stock_bajo_count ?> Prod.</p>
                </div>
                <div class="kpi-card">
                    <h3>Usuarios Activos</h3>
                    <p class="kpi-value"><?= $kpis['total_usuarios'] ?? 0 ?></p>
                </div>
            </div>
        </section>

        <!-- PRODUCTOS -->
        <section id="tab-productos" class="tab-content <?= ($tabActiva === 'productos') ? 'active' : '' ?>">
            <div class="action-bar">
                <h2>Gestión de Productos</h2>
                <div class="filtro-categoria">
                    <label for="categoria">Filtrar por categoría:</label>
                    <select id="categoria" onchange="location.href='?tab=productos&cat=' + this.value">
                        <option value="">Todas las categorías</option>
                        <?php foreach($categorias as $cat): ?>
                            <option value="<?= $cat['id_categoria'] ?>" <?= $filtro_cat == $cat['id_categoria'] ? 'selected' : '' ?>><?= $cat['nombre_categoria'] ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <button class="btn btn-primary" onclick="toggleForm('productoForm')">+ Añadir Producto</button>
            </div>

            <div id="productoForm" class="compra-form" style="display:none;">
                <form method="POST">
                    <input type="hidden" name="tab" value="productos">
                    <input type="hidden" name="action" value="crear_producto">
                    <div class="compra-form-grid">
                        <div>
                            <label>Nombre del producto</label>
                            <input type="text" name="nombre" required placeholder="Ej: Cuaderno Norma">
                        </div>
                        <div>
                            <label>Proveedor</label>
                            <select name="id_proveedor" required>
                                <?php foreach($proveedores as $prov): ?>
                                    <option value="<?= $prov['id_proovedores'] ?>"><?= $prov['nombre'] ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div>
                            <label>Categoría</label>
                            <select name="id_categoria" required>
                                <?php foreach($categorias as $cat): ?>
                                    <option value="<?= $cat['id_categoria'] ?>"><?= $cat['nombre_categoria'] ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div>
                            <label>Precio de compra</label>
                            <input type="number" step="0.01" name="precio_compra" required value="1000">
                        </div>
                        <div>
                            <label>Precio de venta</label>
                            <input type="number" step="0.01" name="precio_venta" required value="1500">
                        </div>
                        <div>
                            <label>Stock inicial</label>
                            <input type="number" name="stock_actual" required value="10">
                        </div>
                        <div>
                            <label>Stock mínimo</label>
                            <input type="number" name="stock_minimo" required value="5">
                        </div>
                        <div>
                            <label>URL Imagen</label>
                            <input type="text" name="url_imagen" placeholder="imagen.jpg">
                        </div>
                    </div>
                    <div style="margin-top:14px; display:flex; gap:10px;">
                        <button type="submit" class="btn btn-primary">Guardar producto</button>
                        <button type="button" class="btn btn-sm" onclick="toggleForm('productoForm')">Cancelar</button>
                    </div>
                </form>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre</th>
                        <th>Proveedor</th>
                        <th>P. Compra</th>
                        <th>P. Venta</th>
                        <th>Stock Actual</th>
                        <th>Stock Mín.</th>
                        <th>Categoría</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach($productos as $prod): ?>
                    <tr>
                        <td><?= $prod['id_producto'] ?></td>
                        <td><?= htmlspecialchars($prod['nombre']) ?></td>
                        <td><?= htmlspecialchars($prod['proveedor']) ?></td>
                        <td>$<?= number_format($prod['precio_compra'], 2) ?></td>
                        <td>$<?= number_format($prod['precio_venta'], 2) ?></td>
                        <td><span class="badge <?= $prod['stock_actual'] <= $prod['stock_minimo'] ? 'danger' : 'success' ?>"><?= $prod['stock_actual'] ?></span></td>
                        <td><?= $prod['stock_minimo'] ?></td>
                        <td><?= htmlspecialchars($prod['nombre_categoria']) ?></td>
                        <td>
                            <button class="btn-edit" onclick='openEditModal("editarProductoModal", <?= json_encode($prod) ?>)'>Editar</button>
                            <form method="POST" style="display:inline;" onsubmit="return confirm('¿Eliminar producto?');">
                                <input type="hidden" name="tab" value="productos">
                                <input type="hidden" name="action" value="eliminar_producto">
                                <input type="hidden" name="id_producto" value="<?= $prod['id_producto'] ?>">
                                <button type="submit" class="btn btn-sm btn-delete">Eliminar</button>
                            </form>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- CATEGORÍAS -->
        <section id="tab-categorias" class="tab-content <?= ($tabActiva === 'categorias') ? 'active' : '' ?>">
            <div class="action-bar">
                <h2>Categorías de Producto</h2>
                <button class="btn btn-primary" onclick="toggleForm('categoriaForm')">+ Añadir Categoría</button>
            </div>

            <div id="categoriaForm" class="compra-form" style="display:none;">
                <form method="POST">
                    <input type="hidden" name="tab" value="categorias">
                    <input type="hidden" name="action" value="crear_categoria">
                    <div class="compra-form-grid">
                        <div>
                            <label>Nombre de la categoría</label>
                            <input type="text" name="nombre_categoria" required>
                        </div>
                        <div>
                            <label>Descripción</label>
                            <input type="text" name="descripcion">
                        </div>
                    </div>
                    <div style="margin-top:14px; display:flex; gap:10px;">
                        <button type="submit" class="btn btn-primary">Guardar categoría</button>
                        <button type="button" class="btn btn-sm" onclick="toggleForm('categoriaForm')">Cancelar</button>
                    </div>
                </form>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre</th>
                        <th>Descripción</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach($categorias as $cat): ?>
                    <tr>
                        <td><?= $cat['id_categoria'] ?></td>
                        <td><?= htmlspecialchars($cat['nombre_categoria']) ?></td>
                        <td><?= htmlspecialchars($cat['descripcion']) ?></td>
                        <td>
                            <button class="btn-edit" onclick='openEditModal("editarCategoriaModal", <?= json_encode($cat) ?>)'>Editar</button>
                            <form method="POST" style="display:inline;" onsubmit="return confirm('¿Eliminar categoría?');">
                                <input type="hidden" name="tab" value="categorias">
                                <input type="hidden" name="action" value="eliminar_categoria">
                                <input type="hidden" name="id_categoria" value="<?= $cat['id_categoria'] ?>">
                                <button type="submit" class="btn btn-sm btn-delete">Eliminar</button>
                            </form>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- PROVEEDORES -->
        <section id="tab-proveedores" class="tab-content <?= ($tabActiva === 'proveedores') ? 'active' : '' ?>">
            <div class="action-bar">
                <h2>Directorio de Proveedores</h2>
                <button class="btn btn-primary" onclick="toggleForm('proveedorForm')">+ Añadir Proveedor</button>
            </div>

            <div id="proveedorForm" class="compra-form" style="display:none;">
                <form method="POST">
                    <input type="hidden" name="tab" value="proveedores">
                    <input type="hidden" name="action" value="crear_proveedor">
                    <div class="compra-form-grid">
                        <div><label>Nombre / Empresa</label><input type="text" name="nombre" required></div>
                        <div><label>Teléfono</label><input type="text" name="telefono"></div>
                        <div><label>Correo</label><input type="email" name="correo"></div>
                        <div><label>Dirección</label><input type="text" name="direccion"></div>
                    </div>
                    <div style="margin-top:14px; display:flex; gap:10px;">
                        <button type="submit" class="btn btn-primary">Guardar proveedor</button>
                        <button type="button" class="btn btn-sm" onclick="toggleForm('proveedorForm')">Cancelar</button>
                    </div>
                </form>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre</th>
                        <th>Teléfono</th>
                        <th>Correo</th>
                        <th>Dirección</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach($proveedores as $prov): ?>
                    <tr>
                        <td><?= $prov['id_proovedores'] ?></td>
                        <td><?= htmlspecialchars($prov['nombre']) ?></td>
                        <td><?= htmlspecialchars($prov['telefono']) ?></td>
                        <td><?= htmlspecialchars($prov['correo']) ?></td>
                        <td><?= htmlspecialchars($prov['direccion']) ?></td>
                        <td>
                            <button class="btn-edit" onclick='openEditModal("editarProveedorModal", <?= json_encode($prov) ?>)'>Editar</button>
                            <form method="POST" style="display:inline;" onsubmit="return confirm('¿Eliminar proveedor?');">
                                <input type="hidden" name="tab" value="proveedores">
                                <input type="hidden" name="action" value="eliminar_proveedor">
                                <input type="hidden" name="id_proveedor" value="<?= $prov['id_proovedores'] ?>">
                                <button type="submit" class="btn btn-sm btn-delete">Eliminar</button>
                            </form>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- COMPRAS -->
        <section id="tab-compras" class="tab-content <?= ($tabActiva === 'compras') ? 'active' : '' ?>">
            <div class="action-bar">
                <h2>Compras Realizadas a Proveedores</h2>
                <button class="btn btn-primary" onclick="toggleForm('compraForm')">+ Registrar Nueva Compra</button>
            </div>

            <div id="compraForm" class="compra-form" style="display:none;">
                <form method="POST">
                    <input type="hidden" name="tab" value="compras">
                    <input type="hidden" name="action" value="registrar_compra">
                    <div class="compra-form-grid">
                        <div>
                            <label>Proveedor</label>
                            <select name="id_proveedor" required>
                                <?php foreach($proveedores as $prov): ?>
                                    <option value="<?= $prov['id_proovedores'] ?>"><?= $prov['nombre'] ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div>
                            <label>Producto a Reabastecer</label>
                            <select name="id_producto" required>
                                <?php foreach($productos as $p): ?>
                                    <option value="<?= $p['id_producto'] ?>"><?= $p['nombre'] ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div>
                            <label>Cantidad</label>
                            <input type="number" name="cantidad" min="1" value="50" required>
                        </div>
                    </div>
                    <div style="margin-top:14px; display:flex; gap:10px;">
                        <button type="submit" class="btn btn-primary">Registrar compra</button>
                        <button type="button" class="btn btn-sm" onclick="toggleForm('compraForm')">Cancelar</button>
                    </div>
                </form>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID Compra</th>
                        <th>Proveedor</th>
                        <th>Total</th>
                        <th>Fecha</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach($compras_lista as $compra): ?>
                    <tr>
                        <td><?= $compra['id_compra'] ?></td>
                        <td><?= htmlspecialchars($compra['nombre']) ?></td>
                        <td><strong>$<?= number_format($compra['total'], 2) ?></strong></td>
                        <td><?= $compra['fecha_compra'] ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- DESCUENTOS -->
        <section id="tab-descuentos" class="tab-content <?= ($tabActiva === 'descuentos') ? 'active' : '' ?>">
            <div class="action-bar">
                <h2>Gestión de Descuentos</h2>
                <button class="btn btn-primary" onclick="toggleForm('descuentoPromoForm')">+ Añadir Descuento</button>
            </div>

            <div id="descuentoPromoForm" class="compra-form" style="display:none;">
                <form method="POST">
                    <input type="hidden" name="tab" value="descuentos">
                    <input type="hidden" name="action" value="crear_descuento">
                    <div class="compra-form-grid">
                        <div><label>Nombre de la promoción</label><input type="text" name="nombre" required></div>
                        <div><label>Porcentaje (%)</label><input type="number" step="0.01" name="porcentaje" required></div>
                        <div><label>Fecha inicio</label><input type="date" name="fecha_inicio" required></div>
                        <div><label>Fecha fin</label><input type="date" name="fecha_fin" required></div>
                    </div>
                    <div style="margin-top:14px; display:flex; gap:10px;">
                        <button type="submit" class="btn btn-primary">Guardar promoción</button>
                        <button type="button" class="btn btn-sm" onclick="toggleForm('descuentoPromoForm')">Cancelar</button>
                    </div>
                </form>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre</th>
                        <th>Porcentaje</th>
                        <th>Fecha Inicio</th>
                        <th>Fecha Fin</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach($descuentos as $desc): ?>
                    <tr>
                        <td><?= $desc['id_descuento'] ?></td>
                        <td><?= htmlspecialchars($desc['nombre']) ?></td>
                        <td><?= number_format($desc['porcentaje'], 2) ?>%</td>
                        <td><?= $desc['fecha_inicio'] ?></td>
                        <td><?= $desc['fecha_fin'] ?></td>
                        <td><span class="badge <?= $desc['estado'] === 'Activo' ? 'success' : 'danger' ?>"><?= $desc['estado'] ?></span></td>
                        <td>
                            <button class="btn-edit" onclick='openEditModal("editarDescuentoModal", <?= json_encode($desc) ?>)'>Editar</button>
                            <form method="POST" style="display:inline;">
                                <input type="hidden" name="tab" value="descuentos">
                                <input type="hidden" name="action" value="toggle_estado_descuento">
                                <input type="hidden" name="id_descuento" value="<?= $desc['id_descuento'] ?>">
                                <input type="hidden" name="estado_actual" value="<?= $desc['estado'] ?>">
                                <button type="submit" class="btn btn-sm <?= $desc['estado'] === 'Activo' ? '' : 'btn-primary' ?>">
                                    <?= $desc['estado'] === 'Activo' ? 'Desactivar' : 'Activar' ?>
                                </button>
                            </form>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- MÉTODOS DE PAGO -->
        <section id="tab-metodospago" class="tab-content <?= ($tabActiva === 'metodospago') ? 'active' : '' ?>">
            <div class="action-bar">
                <h2>Métodos de Pago</h2>
                <button class="btn btn-primary" onclick="toggleForm('metodoForm')">+ Añadir Método</button>
            </div>

            <div id="metodoForm" class="compra-form" style="display:none;">
                <form method="POST">
                    <input type="hidden" name="tab" value="metodospago">
                    <input type="hidden" name="action" value="crear_metodo">
                    <div class="compra-form-grid">
                        <div><label>Nombre del método</label><input type="text" name="nombre" required></div>
                    </div>
                    <div style="margin-top:14px; display:flex; gap:10px;">
                        <button type="submit" class="btn btn-primary">Guardar método</button>
                        <button type="button" class="btn btn-sm" onclick="toggleForm('metodoForm')">Cancelar</button>
                    </div>
                </form>
            </div>

            <table class="data-table">
                <thead>
                    <tr><th>ID</th><th>Método</th><th>Acciones</th></tr>
                </thead>
                <tbody>
                    <?php foreach($metodos_pago as $m): ?>
                    <tr>
                        <td><?= $m['id_metodo_pago'] ?></td>
                        <td><?= htmlspecialchars($m['nombre']) ?></td>
                        <td>
                            <button class="btn-edit" onclick='openEditModal("editarMetodoModal", <?= json_encode($m) ?>)'>Editar</button>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- PEDIDOS -->
        <section id="tab-pedidos" class="tab-content <?= ($tabActiva === 'pedidos') ? 'active' : '' ?>">
            <h2>Pedidos de Clientes</h2>
            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID Pedido</th>
                        <th>Cliente</th>
                        <th>Fecha Pedido</th>
                        <th>Dirección</th>
                        <th>Teléfono</th>
                        <th>Total Venta</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach($pedidos_lista as $ped): ?>
                    <tr>
                        <td><?= $ped['id_pedido'] ?></td>
                        <td><?= htmlspecialchars($ped['nombre'] . ' ' . $ped['apellido']) ?></td>
                        <td><?= $ped['fecha_pedido'] ?></td>
                        <td><?= htmlspecialchars($ped['direccion']) ?></td>
                        <td><?= htmlspecialchars($ped['telefono']) ?></td>
                        <td>$<?= number_format($ped['total_venta'], 2) ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- VENTAS -->
        <section id="tab-ventas" class="tab-content <?= ($tabActiva === 'ventas') ? 'active' : '' ?>">
            <h2>Histórico de Ventas</h2>
            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID Venta</th>
                        <th>Factura N°</th>
                        <th>Cliente</th>
                        <th>Total</th>
                        <th>Estado Pago</th>
                        <th>Fecha Venta</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach($ventas_lista as $v): ?>
                    <tr>
                        <td><?= $v['id_venta'] ?></td>
                        <td><?= $v['numero_factura'] ?></td>
                        <td><?= htmlspecialchars($v['nombre'] . ' ' . $v['apellido']) ?></td>
                        <td>$<?= number_format($v['total'], 2) ?></td>
                        <td><span class="badge success"><?= $v['estado_pago'] ?></span></td>
                        <td><?= $v['fecha_venta'] ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- USUARIOS -->
        <section id="tab-usuarios" class="tab-content <?= ($tabActiva === 'usuarios') ? 'active' : '' ?>">
            <div class="action-bar">
                <h2>Usuarios y Roles</h2>
                <button class="btn btn-primary" onclick="toggleForm('usuarioForm')">+ Añadir Usuario</button>
            </div>

            <div id="usuarioForm" class="compra-form" style="display:none;">
                <form method="POST">
                    <input type="hidden" name="tab" value="usuarios">
                    <input type="hidden" name="action" value="crear_usuario">
                    <div class="compra-form-grid">
                        <div><label>Nombre</label><input type="text" name="nombre" required></div>
                        <div><label>Apellido</label><input type="text" name="apellido" required></div>
                        <div><label>Correo</label><input type="email" name="correo" required></div>
                        <div><label>Contraseña</label><input type="password" name="contraseña" required></div>
                        <div><label>Teléfono</label><input type="text" name="telefono"></div>
                        <div><label>Dirección</label><input type="text" name="direccion"></div>
                        <div>
                            <label>Rol</label>
                            <select name="id_rol" required>
                                <?php foreach($roles as $r): ?>
                                    <option value="<?= $r['id_rol'] ?>"><?= $r['nombre_rol'] ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div style="margin-top:14px; display:flex; gap:10px;">
                        <button type="submit" class="btn btn-primary">Guardar usuario</button>
                        <button type="button" class="btn btn-sm" onclick="toggleForm('usuarioForm')">Cancelar</button>
                    </div>
                </form>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre</th>
                        <th>Correo</th>
                        <th>Teléfono</th>
                        <th>Rol</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach($usuarios_lista as $u): ?>
                    <tr>
                        <td><?= $u['id_usuario'] ?></td>
                        <td><?= htmlspecialchars($u['nombre'] . ' ' . $u['apellido']) ?></td>
                        <td><?= htmlspecialchars($u['correo']) ?></td>
                        <td><?= htmlspecialchars($u['telefono']) ?></td>
                        <td><span class="badge warning"><?= $u['nombre_rol'] ?></span></td>
                        <td>
                            <button class="btn-edit" onclick='openEditModal("editarUsuarioModal", <?= json_encode($u) ?>)'>Editar</button>
                            <form method="POST" style="display:inline;" onsubmit="return confirm('¿Eliminar usuario?');">
                                <input type="hidden" name="tab" value="usuarios">
                                <input type="hidden" name="action" value="eliminar_usuario">
                                <input type="hidden" name="id_usuario" value="<?= $u['id_usuario'] ?>">
                                <button type="submit" class="btn btn-sm btn-delete">Eliminar</button>
                            </form>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- ROLES -->
        <section id="tab-roles" class="tab-content <?= ($tabActiva === 'roles') ? 'active' : '' ?>">
            <div class="action-bar">
                <h2>Roles del Sistema</h2>
                <button class="btn btn-primary" onclick="toggleForm('rolForm')">+ Añadir Rol</button>
            </div>

            <div id="rolForm" class="compra-form" style="display:none;">
                <form method="POST">
                    <input type="hidden" name="tab" value="roles">
                    <input type="hidden" name="action" value="crear_rol">
                    <div class="compra-form-grid">
                        <div><label>Nombre del Rol</label><input type="text" name="nombre_rol" required></div>
                    </div>
                    <div style="margin-top:14px; display:flex; gap:10px;">
                        <button type="submit" class="btn btn-primary">Guardar rol</button>
                        <button type="button" class="btn btn-sm" onclick="toggleForm('rolForm')">Cancelar</button>
                    </div>
                </form>
            </div>

            <table class="data-table">
                <thead>
                    <tr><th>ID</th><th>Nombre del Rol</th><th>Acciones</th></tr>
                </thead>
                <tbody>
                    <?php foreach($roles as $r): ?>
                    <tr>
                        <td><?= $r['id_rol'] ?></td>
                        <td><span class="badge warning"><?= htmlspecialchars($r['nombre_rol']) ?></span></td>
                        <td>
                            <button class="btn-edit" onclick='openEditModal("editarRolModal", <?= json_encode($r) ?>)'>Editar</button>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

        <!-- LOGS -->
        <section id="tab-logs" class="tab-content <?= ($tabActiva === 'logs') ? 'active' : '' ?>">
            <h2>Logs y Auditoría del Sistema</h2>
            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID Log</th>
                        <th>ID Usuario</th>
                        <th>Acción / Movimiento</th>
                        <th>Fecha y Hora</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach($logs_lista as $log): ?>
                    <tr>
                        <td><?= $log['id_log'] ?></td>
                        <td><?= $log['id_usuario'] ?? 'Sistema' ?></td>
                        <td><?= htmlspecialchars($log['tipo_accion']) ?></td>
                        <td><?= $log['fecha_movimiento'] ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>

    </main>

    <!-- ========================================== -->
    <!-- MODALES DE EDICIÓN FLOTANTES -->
    <!-- ========================================== -->

    <!-- Editar Producto -->
    <div id="editarProductoModal" class="modal-overlay">
        <div class="modal-content">
            <h3>Editar Producto</h3>
            <form method="POST">
                <input type="hidden" name="tab" value="productos">
                <input type="hidden" name="action" value="editar_producto">
                <input type="hidden" name="id_producto" id="edit_prod_id">
                <div class="compra-form-grid">
                    <div><label>Nombre</label><input type="text" name="nombre" id="edit_prod_nombre" required></div>
                    <div>
                        <label>Proveedor</label>
                        <select name="id_proveedor" id="edit_prod_prov" required>
                            <?php foreach($proveedores as $prov): ?>
                                <option value="<?= $prov['id_proovedores'] ?>"><?= $prov['nombre'] ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div>
                        <label>Categoría</label>
                        <select name="id_categoria" id="edit_prod_cat" required>
                            <?php foreach($categorias as $cat): ?>
                                <option value="<?= $cat['id_categoria'] ?>"><?= $cat['nombre_categoria'] ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div><label>Precio Compra</label><input type="number" step="0.01" name="precio_compra" id="edit_prod_pcompra" required></div>
                    <div><label>Precio Venta</label><input type="number" step="0.01" name="precio_venta" id="edit_prod_pventa" required></div>
                    <div><label>Stock Actual</label><input type="number" name="stock_actual" id="edit_prod_stactual" required></div>
                    <div><label>Stock Mínimo</label><input type="number" name="stock_minimo" id="edit_prod_stmin" required></div>
                </div>
                <div style="margin-top:14px; display:flex; gap:10px;">
                    <button type="submit" class="btn btn-primary">Actualizar</button>
                    <button type="button" class="btn btn-sm" onclick="closeModal('editarProductoModal')">Cancelar</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Editar Categoría -->
    <div id="editarCategoriaModal" class="modal-overlay">
        <div class="modal-content">
            <h3>Editar Categoría</h3>
            <form method="POST">
                <input type="hidden" name="tab" value="categorias">
                <input type="hidden" name="action" value="editar_categoria">
                <input type="hidden" name="id_categoria" id="edit_cat_id">
                <div class="compra-form-grid">
                    <div><label>Nombre</label><input type="text" name="nombre_categoria" id="edit_cat_nombre" required></div>
                    <div><label>Descripción</label><input type="text" name="descripcion" id="edit_cat_desc"></div>
                </div>
                <div style="margin-top:14px; display:flex; gap:10px;">
                    <button type="submit" class="btn btn-primary">Actualizar</button>
                    <button type="button" class="btn btn-sm" onclick="closeModal('editarCategoriaModal')">Cancelar</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Editar Proveedor -->
    <div id="editarProveedorModal" class="modal-overlay">
        <div class="modal-content">
            <h3>Editar Proveedor</h3>
            <form method="POST">
                <input type="hidden" name="tab" value="proveedores">
                <input type="hidden" name="action" value="editar_proveedor">
                <input type="hidden" name="id_proveedor" id="edit_prov_id">
                <div class="compra-form-grid">
                    <div><label>Nombre</label><input type="text" name="nombre" id="edit_prov_nombre" required></div>
                    <div><label>Teléfono</label><input type="text" name="telefono" id="edit_prov_tel"></div>
                    <div><label>Correo</label><input type="email" name="correo" id="edit_prov_correo"></div>
                    <div><label>Dirección</label><input type="text" name="direccion" id="edit_prov_dir"></div>
                </div>
                <div style="margin-top:14px; display:flex; gap:10px;">
                    <button type="submit" class="btn btn-primary">Actualizar</button>
                    <button type="button" class="btn btn-sm" onclick="closeModal('editarProveedorModal')">Cancelar</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Editar Descuento -->
    <div id="editarDescuentoModal" class="modal-overlay">
        <div class="modal-content">
            <h3>Editar Descuento</h3>
            <form method="POST">
                <input type="hidden" name="tab" value="descuentos">
                <input type="hidden" name="action" value="editar_descuento">
                <input type="hidden" name="id_descuento" id="edit_desc_id">
                <div class="compra-form-grid">
                    <div><label>Nombre</label><input type="text" name="nombre" id="edit_desc_nombre" required></div>
                    <div><label>Porcentaje (%)</label><input type="number" step="0.01" name="porcentaje" id="edit_desc_porcentaje" required></div>
                    <div><label>Fecha Inicio</label><input type="date" name="fecha_inicio" id="edit_desc_finicio" required></div>
                    <div><label>Fecha Fin</label><input type="date" name="fecha_fin" id="edit_desc_ffin" required></div>
                </div>
                <div style="margin-top:14px; display:flex; gap:10px;">
                    <button type="submit" class="btn btn-primary">Actualizar</button>
                    <button type="button" class="btn btn-sm" onclick="closeModal('editarDescuentoModal')">Cancelar</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Editar Método de Pago -->
    <div id="editarMetodoModal" class="modal-overlay">
        <div class="modal-content">
            <h3>Editar Método de Pago</h3>
            <form method="POST">
                <input type="hidden" name="tab" value="metodospago">
                <input type="hidden" name="action" value="editar_metodo">
                <input type="hidden" name="id_metodo_pago" id="edit_met_id">
                <div class="compra-form-grid">
                    <div><label>Nombre</label><input type="text" name="nombre" id="edit_met_nombre" required></div>
                </div>
                <div style="margin-top:14px; display:flex; gap:10px;">
                    <button type="submit" class="btn btn-primary">Actualizar</button>
                    <button type="button" class="btn btn-sm" onclick="closeModal('editarMetodoModal')">Cancelar</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Editar Usuario -->
    <div id="editarUsuarioModal" class="modal-overlay">
        <div class="modal-content">
            <h3>Editar Usuario</h3>
            <form method="POST">
                <input type="hidden" name="tab" value="usuarios">
                <input type="hidden" name="action" value="editar_usuario">
                <input type="hidden" name="id_usuario" id="edit_usr_id">
                <div class="compra-form-grid">
                    <div><label>Nombre</label><input type="text" name="nombre" id="edit_usr_nombre" required></div>
                    <div><label>Apellido</label><input type="text" name="apellido" id="edit_usr_apellido" required></div>
                    <div><label>Correo</label><input type="email" name="correo" id="edit_usr_correo" required></div>
                    <div><label>Teléfono</label><input type="text" name="telefono" id="edit_usr_tel"></div>
                    <div><label>Dirección</label><input type="text" name="direccion" id="edit_usr_dir"></div>
                    <div>
                        <label>Rol</label>
                        <select name="id_rol" id="edit_usr_rol" required>
                            <?php foreach($roles as $r): ?>
                                <option value="<?= $r['id_rol'] ?>"><?= $r['nombre_rol'] ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>
                <div style="margin-top:14px; display:flex; gap:10px;">
                    <button type="submit" class="btn btn-primary">Actualizar</button>
                    <button type="button" class="btn btn-sm" onclick="closeModal('editarUsuarioModal')">Cancelar</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Editar Rol -->
    <div id="editarRolModal" class="modal-overlay">
        <div class="modal-content">
            <h3>Editar Rol</h3>
            <form method="POST">
                <input type="hidden" name="tab" value="roles">
                <input type="hidden" name="action" value="editar_rol">
                <input type="hidden" name="id_rol" id="edit_rol_id">
                <div class="compra-form-grid">
                    <div><label>Nombre del Rol</label><input type="text" name="nombre_rol" id="edit_rol_nombre" required></div>
                </div>
                <div style="margin-top:14px; display:flex; gap:10px;">
                    <button type="submit" class="btn btn-primary">Actualizar</button>
                    <button type="button" class="btn btn-sm" onclick="closeModal('editarRolModal')">Cancelar</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function switchTab(tabId, element) {
            document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));
            
            const target = document.getElementById('tab-' + tabId);
            if (target) target.classList.add('active');
            
            if (element) {
                element.classList.add('active');
                document.getElementById('section-title').innerText = element.innerText;
            }
        }

        function toggleForm(formId) {
            const form = document.getElementById(formId);
            if (form) {
                form.style.display = (form.style.display === 'none' || form.style.display === '') ? 'block' : 'none';
            }
        }

        function openEditModal(modalId, data) {
            if (modalId === 'editarProductoModal') {
                document.getElementById('edit_prod_id').value = data.id_producto;
                document.getElementById('edit_prod_nombre').value = data.nombre;
                document.getElementById('edit_prod_prov').value = data.id_proveedor;
                document.getElementById('edit_prod_cat').value = data.id_categoria;
                document.getElementById('edit_prod_pcompra').value = data.precio_compra;
                document.getElementById('edit_prod_pventa').value = data.precio_venta;
                document.getElementById('edit_prod_stactual').value = data.stock_actual;
                document.getElementById('edit_prod_stmin').value = data.stock_minimo;
            } else if (modalId === 'editarCategoriaModal') {
                document.getElementById('edit_cat_id').value = data.id_categoria;
                document.getElementById('edit_cat_nombre').value = data.nombre_categoria;
                document.getElementById('edit_cat_desc').value = data.descripcion;
            } else if (modalId === 'editarProveedorModal') {
                document.getElementById('edit_prov_id').value = data.id_proovedores;
                document.getElementById('edit_prov_nombre').value = data.nombre;
                document.getElementById('edit_prov_tel').value = data.telefono;
                document.getElementById('edit_prov_correo').value = data.correo;
                document.getElementById('edit_prov_dir').value = data.direccion;
            } else if (modalId === 'editarDescuentoModal') {
                document.getElementById('edit_desc_id').value = data.id_descuento;
                document.getElementById('edit_desc_nombre').value = data.nombre;
                document.getElementById('edit_desc_porcentaje').value = data.porcentaje;
                document.getElementById('edit_desc_finicio').value = data.fecha_inicio;
                document.getElementById('edit_desc_ffin').value = data.fecha_fin;
            } else if (modalId === 'editarMetodoModal') {
                document.getElementById('edit_met_id').value = data.id_metodo_pago;
                document.getElementById('edit_met_nombre').value = data.nombre;
            } else if (modalId === 'editarUsuarioModal') {
                document.getElementById('edit_usr_id').value = data.id_usuario;
                document.getElementById('edit_usr_nombre').value = data.nombre;
                document.getElementById('edit_usr_apellido').value = data.apellido;
                document.getElementById('edit_usr_correo').value = data.correo;
                document.getElementById('edit_usr_tel').value = data.telefono;
                document.getElementById('edit_usr_dir').value = data.direccion;
                document.getElementById('edit_usr_rol').value = data.id_rol;
            } else if (modalId === 'editarRolModal') {
                document.getElementById('edit_rol_id').value = data.id_rol;
                document.getElementById('edit_rol_nombre').value = data.nombre_rol;
            }
            
            document.getElementById(modalId).style.display = 'flex';
        }

        function closeModal(modalId) {
            document.getElementById(modalId).style.display = 'none';
        }
    </script>
</body>
</html>