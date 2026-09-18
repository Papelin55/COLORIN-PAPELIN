-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 10-09-2026 a las 05:58:34
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `colorinpapelin_def`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_precio` (IN `p_producto` INT, IN `p_precio` DECIMAL(10,2))   BEGIN

UPDATE producto

SET precio_venta=p_precio

WHERE id_producto=p_producto;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_producto` (IN `p_id_usuario` INT, IN `p_id_producto` INT, IN `p_id_proveedor` INT, IN `p_nombre` VARCHAR(150), IN `p_descripcion` VARCHAR(500), IN `p_precio_compra` DECIMAL(10,2), IN `p_precio_venta` DECIMAL(10,2), IN `p_url_imagen` VARCHAR(255), IN `p_stock_actual` INT, IN `p_stock_minimo` INT, IN `p_id_categoria` INT)   BEGIN

    UPDATE producto
    SET

        id_proveedor = p_id_proveedor,
        nombre = p_nombre,
        descripcion = p_descripcion,
        precio_compra = p_precio_compra,
        precio_venta = p_precio_venta,
        url_imagen = p_url_imagen,
        stock_actual = p_stock_actual,
        stock_minimo = p_stock_minimo,
        id_categoria = p_id_categoria

    WHERE id_producto = p_id_producto;


    INSERT INTO logs
    (
        id_usuario,
        tipo_accion,
        fecha_movimiento
    )

    VALUES
    (
        p_id_usuario,
        CONCAT('Producto actualizado: ',p_nombre),
        NOW()
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_agregar_producto_pedido` (IN `p_id_pedido` INT, IN `p_id_producto` INT, IN `p_cantidad` INT)   BEGIN

    DECLARE v_precio DECIMAL(10,2);

    
    SELECT precio_venta
    INTO v_precio
    FROM producto
    WHERE id_producto = p_id_producto;

    
    INSERT INTO detalles_pedido
    (
        id_pedido,
        id_producto,
        cantidad,
        precio_unitario,
        estado_pedido
    )
    VALUES
    (
        p_id_pedido,
        p_id_producto,
        p_cantidad,
        v_precio,
        'Pendiente'
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_categoria` (IN `p_categoria` INT)   BEGIN

SELECT *

FROM producto

WHERE id_categoria=p_categoria;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_producto` (IN `p_nombre` VARCHAR(150))   BEGIN

SELECT *

FROM producto

WHERE nombre LIKE CONCAT('%',p_nombre,'%');

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_confirmar_pedido` (IN `p_id_pedido` INT)   BEGIN

    UPDATE pedidos
    SET estado = 1
    WHERE id_pedido = p_id_pedido;

    INSERT INTO ventas
    (
        id_pedido,
        id_usuario,
        fecha_venta,
        subtotal,
        descuentos,
        cantidad_productos,
        total,
        estado_pago,
        numero_factura
    )
    SELECT
        p.id_pedido,
        p.id_usuario,
        NOW(),
        p.total_venta,
        IFNULL(d.porcentaje,0),
        (
            SELECT IFNULL(SUM(cantidad),0)
            FROM detalles_pedido
            WHERE id_pedido = p.id_pedido
        ),
        p.total_venta - (p.total_venta * IFNULL(d.porcentaje,0) / 100),
        'Pagado',
        CONCAT('FAC-', p.id_pedido)
    FROM pedidos p
    LEFT JOIN descuentos d
        ON p.id_descuento = d.id_descuento
    WHERE p.id_pedido = p_id_pedido;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_pedido` (IN `p_id_usuario` INT, IN `p_id_descuento` INT)   BEGIN

    INSERT INTO pedidos
    (
        id_usuario,
        id_descuento,
        fecha_pedido,
        total_venta,
        estado
    )
    VALUES
    (
        p_id_usuario,
        p_id_descuento,
        NOW(),
        0,
        0
    );

    SELECT LAST_INSERT_ID() AS id_pedido;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dashboard` ()   BEGIN

SELECT

(SELECT COUNT(*) FROM usuario) AS total_usuarios,

(SELECT COUNT(*) FROM producto) AS total_productos,

(SELECT COUNT(*) FROM compras) AS total_compras,

(SELECT COUNT(*) FROM ventas) AS total_ventas,

(SELECT IFNULL(SUM(total),0) FROM ventas) AS dinero_vendido,

(SELECT IFNULL(SUM(total),0) FROM compras) AS dinero_comprado;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_historial_ventas` (IN `p_usuario` INT)   BEGIN

SELECT *

FROM ventas

WHERE id_usuario=p_usuario

ORDER BY fecha_venta DESC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_productos_mas_vendidos` ()   BEGIN

SELECT

p.id_producto,
p.nombre,

SUM(dp.cantidad) AS total_vendido

FROM producto p

INNER JOIN detalles_pedido dp

ON p.id_producto=dp.id_producto

GROUP BY p.id_producto,p.nombre

ORDER BY total_vendido DESC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_realizar_compra` (IN `p_id_usuario` INT, IN `p_id_producto` INT, IN `p_cantidad` INT)   BEGIN

    DECLARE v_stock INT;
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_id_pedido INT;

    
    SELECT stock_actual, precio_venta
    INTO v_stock, v_precio
    FROM producto
    WHERE id_producto = p_id_producto;

    
    IF v_stock < p_cantidad THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente para realizar la compra';

    ELSE

        
        SET v_total = v_precio * p_cantidad;

        
        INSERT INTO pedidos
        (
            id_usuario,
            id_descuento,
            fecha_pedido,
            total_venta,
            estado
        )
        VALUES
        (
            p_id_usuario,
            NULL,
            NOW(),
            0,
            0
        );

        
        SET v_id_pedido = LAST_INSERT_ID();

        
        INSERT INTO detalles_pedido
        (
            id_pedido,
            id_producto,
            cantidad,
            precio_unitario,
            estado_pedido
        )
        VALUES
        (
            v_id_pedido,
            p_id_producto,
            p_cantidad,
            v_precio,
            'Pendiente'
        );

        

    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_compra` (IN `p_id_usuario` INT, IN `p_id_proveedor` INT, IN `p_id_producto` INT, IN `p_cantidad` INT)   BEGIN

    DECLARE v_id_compra INT;
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_precio_compra DECIMAL(10,2);
    DECLARE v_rol INT;

    
    SELECT id_rol
    INTO v_rol
    FROM usuario
    WHERE id_usuario = p_id_usuario;

    IF v_rol <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Solo los administradores pueden registrar compras.';
    END IF;

    
    SELECT precio_compra
    INTO v_precio_compra
    FROM producto
    WHERE id_producto = p_id_producto;

    SET v_total = p_cantidad * v_precio_compra;

    INSERT INTO compras
    (
        id_proveedor,
        id_usuario,
        fecha_compra,
        total
    )
    VALUES
    (
        p_id_proveedor,
        p_id_usuario,
        NOW(),
        v_total
    );

    SET v_id_compra = LAST_INSERT_ID();

    INSERT INTO detalles_compra
    (
        id_compra,
        id_producto,
        cantidad,
        precio_compra
    )
    VALUES
    (
        v_id_compra,
        p_id_producto,
        p_cantidad,
        v_precio_compra
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_producto` (IN `p_id_proveedor` INT, IN `p_nombre` VARCHAR(150), IN `p_descripcion` VARCHAR(500), IN `p_precio_compra` DECIMAL(10,2), IN `p_precio_venta` DECIMAL(10,2), IN `p_url_imagen` VARCHAR(255), IN `p_stock_actual` INT, IN `p_stock_minimo` INT, IN `p_id_categoria` INT)   BEGIN

    INSERT INTO producto
    (
        id_proveedor,
        nombre,
        descripcion,
        precio_compra,
        precio_venta,
        url_imagen,
        stock_actual,
        stock_minimo,
        id_categoria
    )

    VALUES
    (
        p_id_proveedor,
        p_nombre,
        p_descripcion,
        p_precio_compra,
        p_precio_venta,
        p_url_imagen,
        p_stock_actual,
        p_stock_minimo,
        p_id_categoria
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_usuario` (IN `p_nombre` VARCHAR(100), IN `p_apellido` VARCHAR(100), IN `p_correo` VARCHAR(120), IN `p_contraseña` VARCHAR(255), IN `p_telefono` VARCHAR(20), IN `p_telefono2` VARCHAR(20), IN `p_direccion` VARCHAR(200), IN `p_id_rol` INT)   BEGIN

INSERT INTO usuario
(
nombre,
apellido,
correo,
contraseña,
telefono,
telefono_secundario,
direccion,
id_rol
)

VALUES
(
p_nombre,
p_apellido,
p_correo,
p_contraseña,
p_telefono,
p_telefono2,
p_direccion,
p_id_rol
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_stock_bajo` ()   BEGIN

SELECT *

FROM producto

WHERE stock_actual<=stock_minimo;

END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_precio_producto` (`p_id_producto` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN

    DECLARE v_precio DECIMAL(10,2);

    SELECT precio_venta
    INTO v_precio
    FROM producto
    WHERE id_producto=p_id_producto;

    RETURN v_precio;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_productos_vendidos` (`p_producto` INT) RETURNS INT(11) DETERMINISTIC BEGIN

    DECLARE v_total INT;

    SELECT IFNULL(SUM(cantidad),0)
    INTO v_total
    FROM detalles_pedido
    WHERE id_producto=p_producto;

    RETURN v_total;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_stock_producto` (`p_id_producto` INT) RETURNS INT(11) DETERMINISTIC BEGIN

    DECLARE v_stock INT;

    SELECT stock_actual
    INTO v_stock
    FROM producto
    WHERE id_producto = p_id_producto;

    RETURN v_stock;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_total_pedido` (`p_id_pedido` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN

    DECLARE v_total DECIMAL(10,2);

    SELECT IFNULL(SUM(valor_total),0)
    INTO v_total
    FROM detalles_pedido
    WHERE id_pedido=p_id_pedido;

    RETURN v_total;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_total_ventas_usuario` (`p_usuario` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN

    DECLARE v_total DECIMAL(10,2);

    SELECT IFNULL(SUM(total),0)
    INTO v_total
    FROM ventas
    WHERE id_usuario=p_usuario;

    RETURN v_total;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `carrito`
--

CREATE TABLE `carrito` (
  `id_carrito` int(11) NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria`
--

CREATE TABLE `categoria` (
  `id_categoria` int(11) NOT NULL,
  `nombre_categoria` varchar(100) NOT NULL,
  `descripcion` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categoria`
--

INSERT INTO `categoria` (`id_categoria`, `nombre_categoria`, `descripcion`) VALUES
(1, 'Cuadernos', 'Cuadernos de todo tipo'),
(2, 'Lápices', 'Lápices y colores'),
(3, 'Marcadores', 'Marcadores permanentes'),
(4, 'Papelería', 'Artículos de oficina'),
(5, 'Arte', 'Material para dibujo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `id_compra` int(11) NOT NULL,
  `id_proveedor` int(11) DEFAULT NULL,
  `id_usuario` int(11) NOT NULL,
  `fecha_compra` datetime DEFAULT NULL,
  `total` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `compras`
--

INSERT INTO `compras` (`id_compra`, `id_proveedor`, `id_usuario`, `fecha_compra`, `total`) VALUES
(1, 1, 1, '2026-08-04 15:40:14', 150000.00),
(2, 2, 1, '2026-08-04 15:40:14', 200000.00),
(3, 1, 1, '2026-08-04 15:47:53', 120000.00),
(4, 2, 1, '2026-08-06 08:40:17', 500.00),
(5, 1, 1, '2026-08-06 08:47:01', 1000.00),
(6, 1, 1, '2026-08-06 08:48:46', 120000.00),
(7, 1, 1, '2026-08-06 08:55:08', 175000.00),
(8, 1, 1, '2026-08-06 08:55:39', 0.00),
(9, 1, 1, '2026-08-06 09:09:10', 120000.00),
(10, 1, 1, '2026-08-06 09:10:12', 175000.00),
(11, 1, 1, '2026-08-06 09:15:12', 35000.00),
(12, 1, 1, '2026-08-06 09:50:45', 100000.00),
(13, 1, 1, '2026-08-06 09:52:19', 500000.00),
(14, 2, 1, '2026-08-06 14:14:20', 500000.00);

--
-- Disparadores `compras`
--
DELIMITER $$
CREATE TRIGGER `tr_log_compra` AFTER INSERT ON `compras` FOR EACH ROW BEGIN

    INSERT INTO logs
    (
        id_usuario,
        tipo_accion,
        fecha_movimiento
    )
    VALUES
    (
        NEW.id_usuario,
        CONCAT('Compra registrada #', NEW.id_compra),
        NOW()
    );

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `descuentos`
--

CREATE TABLE `descuentos` (
  `id_descuento` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `porcentaje` decimal(5,2) DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `estado` enum('Activo','Inactivo') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `descuentos`
--

INSERT INTO `descuentos` (`id_descuento`, `nombre`, `porcentaje`, `fecha_inicio`, `fecha_fin`, `estado`) VALUES
(1, 'Sin descuento', 0.00, '2025-01-01', '2030-12-31', 'Activo'),
(2, 'Escolar', 10.00, '2025-01-01', '2025-12-31', 'Inactivo'),
(3, 'Navidad', 15.00, '2025-12-01', '2025-12-31', 'Inactivo'),
(4, 'Cliente VIP', 20.00, '2025-01-01', '2030-12-31', 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_compra`
--

CREATE TABLE `detalles_compra` (
  `id_detalle_compra` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio_compra` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalles_compra`
--

INSERT INTO `detalles_compra` (`id_detalle_compra`, `id_compra`, `id_producto`, `cantidad`, `precio_compra`) VALUES
(4, 3, 11, 50, 3500.00),
(5, 3, 11, 50, 3500.00),
(7, 7, 2, 50, 3500.00),
(8, 8, 2, 500, 0.00),
(9, 10, 2, 50, 3500.00),
(10, 11, 2, 10, 3500.00),
(11, 12, 2, 20, 5000.00),
(12, 13, 2, 100, 5000.00),
(13, 14, 2, 100, 5000.00);

--
-- Disparadores `detalles_compra`
--
DELIMITER $$
CREATE TRIGGER `tr_reabastecer_stock` AFTER INSERT ON `detalles_compra` FOR EACH ROW BEGIN

UPDATE producto

SET stock_actual=
stock_actual+NEW.cantidad

WHERE id_producto=NEW.id_producto;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_pedido`
--

CREATE TABLE `detalles_pedido` (
  `id_detalle` int(11) NOT NULL,
  `id_pedido` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio_unitario` decimal(10,2) DEFAULT NULL,
  `estado_pedido` varchar(50) DEFAULT NULL,
  `valor_total` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalles_pedido`
--

INSERT INTO `detalles_pedido` (`id_detalle`, `id_pedido`, `id_producto`, `cantidad`, `precio_unitario`, `estado_pedido`, `valor_total`) VALUES
(4, 3, 11, 3, 6500.00, 'Pendiente', 19500.00),
(5, 4, 2, 10, 7000.00, 'Pendiente', 70000.00),
(6, 7, 2, 67, 7000.00, 'Pendiente', 469000.00),
(7, 8, 2, 10, 7000.00, 'Pendiente', 70000.00),
(8, 9, 2, 10, 7000.00, 'Pendiente', 70000.00),
(9, 10, 5, 10, 4000.00, 'Pendiente', 40000.00),
(10, 11, 5, 10, 4000.00, 'Pendiente', 40000.00),
(11, 12, 3, 50, 1000.00, 'Pendiente', 50000.00),
(12, 13, 3, 50, 1000.00, 'Pendiente', 50000.00),
(13, 14, 2, 2, 7000.00, 'Pendiente', 14000.00),
(15, 16, 2, 100, 7000.00, 'Pendiente', 700000.00),
(16, 17, 2, 100, 7000.00, 'Pendiente', 700000.00),
(17, 18, 2, 100, 7000.00, 'Pendiente', 700000.00),
(18, 19, 2, 100, 7000.00, 'Pendiente', 700000.00),
(19, 20, 2, 100, 7000.00, 'Pendiente', 700000.00),
(20, 21, 2, 100, 7000.00, 'Pendiente', 700000.00),
(21, 22, 2, 100, 7000.00, 'Pendiente', 700000.00),
(22, 24, 3, 50, 1000.00, 'Pendiente', 50000.00),
(23, 25, 3, 10, 1000.00, 'Pendiente', 10000.00),
(24, 25, 4, 10, 0.00, 'Pendiente', 0.00),
(25, 25, 5, 1, 4000.00, 'Pendiente', 4000.00),
(26, 25, 8, 4, 1500.00, 'Pendiente', 6000.00),
(27, 25, 3, 10, 1000.00, 'Pendiente', 10000.00),
(28, 27, 2, 10, 7000.00, 'Pendiente', 70000.00),
(29, 28, 2, 10, 7000.00, 'Pendiente', 70000.00),
(30, 28, 5, 29, 4000.00, 'Pendiente', 116000.00),
(31, 29, 3, 10, 1000.00, 'Pendiente', 10000.00),
(32, 30, 2, 52, 7000.00, 'Pendiente', 364000.00),
(33, 30, 8, 100, 1500.00, 'Pendiente', 150000.00);

--
-- Disparadores `detalles_pedido`
--
DELIMITER $$
CREATE TRIGGER `tr_actualizar_total_pedido` AFTER INSERT ON `detalles_pedido` FOR EACH ROW BEGIN

UPDATE pedidos

SET total_venta=

(
SELECT SUM(valor_total)

FROM detalles_pedido

WHERE id_pedido=NEW.id_pedido
)

WHERE id_pedido=NEW.id_pedido;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_calcular_valor_total` BEFORE INSERT ON `detalles_pedido` FOR EACH ROW BEGIN

    SET NEW.valor_total =
    NEW.cantidad * NEW.precio_unitario;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_descontar_stock` AFTER INSERT ON `detalles_pedido` FOR EACH ROW BEGIN

    UPDATE producto

    SET stock_actual =
    stock_actual - NEW.cantidad

    WHERE id_producto = NEW.id_producto;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_validar_stock` BEFORE INSERT ON `detalles_pedido` FOR EACH ROW BEGIN

    DECLARE v_stock INT;

    SELECT stock_actual
    INTO v_stock
    FROM producto
    WHERE id_producto = NEW.id_producto;

    IF NEW.cantidad > v_stock THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Stock insuficiente.';
    END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs`
--

CREATE TABLE `logs` (
  `id_log` int(11) NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `tipo_accion` varchar(200) DEFAULT NULL,
  `fecha_movimiento` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `logs`
--

INSERT INTO `logs` (`id_log`, `id_usuario`, `tipo_accion`, `fecha_movimiento`) VALUES
(1, 1, 'Nuevo usuario registrado', '2026-08-04 15:39:48'),
(2, 2, 'Nuevo usuario registrado', '2026-08-04 15:39:48'),
(3, 3, 'Nuevo usuario registrado', '2026-08-04 15:39:48'),
(4, 4, 'Nuevo usuario registrado', '2026-08-04 15:39:48'),
(5, NULL, 'Compra registrada #1', '2026-08-04 15:40:14'),
(6, NULL, 'Compra registrada #2', '2026-08-04 15:40:14'),
(7, NULL, 'Verificación automática del sistema', '2026-08-04 15:45:41'),
(8, 6, 'Nuevo usuario registrado', '2026-08-04 15:46:55'),
(9, NULL, 'Producto actualizado: Borrador Nata', '2026-08-04 15:47:24'),
(10, NULL, 'Compra registrada #3', '2026-08-04 15:47:53'),
(11, NULL, 'Producto actualizado: Borrador Nata', '2026-08-04 15:48:02'),
(12, NULL, 'Producto actualizado: Borrador Nata', '2026-08-04 15:48:08'),
(13, NULL, 'Producto actualizado: Borrador Nata', '2026-08-04 15:48:22'),
(14, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 08:10:41'),
(15, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 08:11:58'),
(16, 3, 'Compra realizada. Producto ID: 1, Cantidad: 2', '2026-08-06 08:23:12'),
(17, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 08:24:24'),
(18, 3, 'Producto actualizado', '2026-08-06 08:28:54'),
(19, NULL, 'Producto actualizado: Marcador Permanente', '2026-08-06 08:34:17'),
(20, NULL, 'Producto actualizado: Lápiz HB', '2026-08-06 08:36:22'),
(21, NULL, 'Producto actualizado: Lápiz HB', '2026-08-06 08:36:44'),
(22, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 08:38:43'),
(23, NULL, 'Compra registrada #4', '2026-08-06 08:40:17'),
(24, NULL, 'Compra registrada #5', '2026-08-06 08:47:01'),
(25, NULL, 'Compra registrada #6', '2026-08-06 08:48:46'),
(26, NULL, 'Compra registrada #7', '2026-08-06 08:55:08'),
(27, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 08:55:08'),
(28, NULL, 'Compra registrada #8', '2026-08-06 08:55:39'),
(29, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 08:55:39'),
(30, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 09:00:49'),
(31, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 09:03:50'),
(32, 1, 'Compra registrada #10', '2026-08-06 09:10:12'),
(33, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 09:10:12'),
(34, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 09:10:30'),
(35, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 09:11:09'),
(36, 1, 'Compra registrada #11', '2026-08-06 09:15:12'),
(37, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 09:15:12'),
(38, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 09:19:32'),
(39, NULL, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 09:21:30'),
(40, 1, 'Producto actualizado: Cuaderno Norma 100 hojas', '2026-08-06 09:27:54'),
(41, 1, 'Compra registrada #12', '2026-08-06 09:50:45'),
(42, 1, 'Compra registrada #13', '2026-08-06 09:52:19'),
(43, 1, 'Compra registrada #14', '2026-08-06 14:14:20'),
(44, 7, 'Nuevo usuario registrado', '2026-09-09 15:35:22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `metodo_pago`
--

CREATE TABLE `metodo_pago` (
  `id_metodo_pago` int(11) NOT NULL,
  `nombre` varchar(60) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `metodo_pago`
--

INSERT INTO `metodo_pago` (`id_metodo_pago`, `nombre`) VALUES
(1, 'Efectivo'),
(2, 'Nequi');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos`
--

CREATE TABLE `pedidos` (
  `id_pedido` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `id_descuento` int(11) DEFAULT NULL,
  `fecha_pedido` datetime DEFAULT NULL,
  `total_venta` decimal(10,2) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pedidos`
--

INSERT INTO `pedidos` (`id_pedido`, `id_usuario`, `id_descuento`, `fecha_pedido`, `total_venta`, `estado`) VALUES
(1, 3, 1, '2026-08-04 15:39:58', 0.00, 0),
(2, 4, 2, '2026-08-04 15:39:58', 0.00, 0),
(3, 3, 1, '2026-08-04 15:48:17', 19500.00, 1),
(4, 1, NULL, '2026-08-06 08:10:41', 70000.00, 0),
(7, 1, NULL, '2026-08-06 08:11:58', 469000.00, 0),
(8, 1, NULL, '2026-08-06 08:24:24', 70000.00, 0),
(9, 1, NULL, '2026-08-06 08:30:08', 70000.00, 0),
(10, 2, NULL, '2026-08-06 08:31:48', 40000.00, 0),
(11, 1, NULL, '2026-08-06 08:34:17', 40000.00, 0),
(12, 2, NULL, '2026-08-06 08:36:22', 50000.00, 0),
(13, 2, NULL, '2026-08-06 08:36:44', 50000.00, 0),
(14, 2, NULL, '2026-08-06 08:38:43', 14000.00, 0),
(15, 1, NULL, '2026-08-06 09:00:44', 0.00, 0),
(16, 1, NULL, '2026-08-06 09:00:49', 700000.00, 0),
(17, 1, NULL, '2026-08-06 09:03:50', 700000.00, 0),
(18, 1, NULL, '2026-08-06 09:10:30', 700000.00, 0),
(19, 1, NULL, '2026-08-06 09:11:09', 700000.00, 0),
(20, 1, NULL, '2026-08-06 09:19:32', 700000.00, 0),
(21, 1, NULL, '2026-08-06 09:21:30', 700000.00, 0),
(22, 1, NULL, '2026-08-06 09:28:27', 700000.00, 0),
(23, 1, NULL, '2026-08-06 09:30:43', 0.00, 0),
(24, 1, NULL, '2026-08-06 09:34:19', 50000.00, 0),
(25, 1, NULL, '2026-08-06 09:36:29', 30000.00, 0),
(27, 1, NULL, '2026-08-06 09:54:07', 70000.00, 0),
(28, 1, NULL, '2026-08-06 09:56:09', 186000.00, 0),
(29, 2, NULL, '2026-08-06 10:00:31', 10000.00, 0),
(30, 1, NULL, '2026-08-06 14:02:24', 514000.00, 1),
(33, 1, 1, '2026-08-06 14:32:24', 0.00, 0);

--
-- Disparadores `pedidos`
--
DELIMITER $$
CREATE TRIGGER `tr_generar_venta` AFTER UPDATE ON `pedidos` FOR EACH ROW BEGIN

IF NEW.estado=1
AND OLD.estado<>1 THEN

INSERT INTO ventas
(
id_pedido,
id_usuario,
fecha_venta,
subtotal,
descuentos,
cantidad_productos,
total,
estado_pago,
numero_factura
)

VALUES
(
NEW.id_pedido,
NEW.id_usuario,
NOW(),
NEW.total_venta,
0,

(
SELECT IFNULL(SUM(cantidad),0)

FROM detalles_pedido

WHERE id_pedido=NEW.id_pedido
),

NEW.total_venta,

'Pagado',

CONCAT('FAC-',NEW.id_pedido)
);

END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `id_producto` int(11) NOT NULL,
  `id_proveedor` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `descripcion` varchar(500) DEFAULT NULL,
  `precio_compra` decimal(10,2) NOT NULL,
  `precio_venta` decimal(10,2) NOT NULL,
  `url_imagen` varchar(255) DEFAULT NULL,
  `stock_actual` int(11) NOT NULL,
  `stock_minimo` int(11) NOT NULL,
  `id_categoria` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`id_producto`, `id_proveedor`, `nombre`, `descripcion`, `precio_compra`, `precio_venta`, `url_imagen`, `stock_actual`, `stock_minimo`, `id_categoria`) VALUES
(2, 1, 'Cuaderno Norma 100 hojas', 'Cuaderno rayado', 5000.00, 7000.00, 'cuaderno.jpg', 148, 20, 1),
(3, 2, 'Lápiz HB', 'Lápiz negro HB', 500.00, 1000.00, 'lapiz.jpg', 120, 50, 2),
(4, 2, 'Caja de colores', 'Caja x12 colores', 7000.00, 10000.00, 'colores.jpg', 70, 20, 2),
(5, 3, 'Marcador Permanente', 'Color negro', 2500.00, 4000.00, 'marcador.jpg', 100, 30, 3),
(6, 4, 'Resaltador Stabilo', 'Color amarillo', 2500.00, 4500.00, 'stabilo.jpg', 120, 20, 3),
(7, 5, 'Resma Carta', '500 hojas', 18000.00, 24000.00, 'resma.jpg', 50, 10, 4),
(8, 5, 'Cartulina Blanca', 'Pliego', 900.00, 1500.00, 'cartulina.jpg', 146, 50, 4),
(9, 3, 'Tempera x6', 'Caja de témperas', 8000.00, 12000.00, 'tempera.jpg', 40, 10, 5),
(10, 1, 'Regla 30 cm', 'Regla transparente', 1200.00, 2500.00, 'regla.jpg', 90, 20, 4),
(11, 4, 'Borrador Nata', 'Borrador blanco', 600.00, 6500.00, 'borrador.jpg', 277, 30, 2),
(12, 1, 'Resaltador Stabilo', 'Color amarillo', 2500.00, 4000.00, 'stabilo.jpg', 100, 20, 1),
(13, 1, 'Tijeras Escolares', 'Tijeras punta roma', 3500.00, 5500.00, 'tijeras.jpg', 80, 15, 4);

--
-- Disparadores `producto`
--
DELIMITER $$
CREATE TRIGGER `tr_log_producto_delete` BEFORE DELETE ON `producto` FOR EACH ROW BEGIN

INSERT INTO logs
(
id_usuario,
tipo_accion,
fecha_movimiento
)

VALUES
(
NULL,
CONCAT('Producto eliminado: ',OLD.nombre),
NOW()
);

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proovedores`
--

CREATE TABLE `proovedores` (
  `id_proovedores` int(11) NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `correo` varchar(120) DEFAULT NULL,
  `direccion` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `proovedores`
--

INSERT INTO `proovedores` (`id_proovedores`, `nombre`, `telefono`, `correo`, `direccion`) VALUES
(1, 'Norma', '3001111111', 'ventas@norma.com', 'Bogotá'),
(2, 'Faber Castell', '3002222222', 'ventas@faber.com', 'Medellín'),
(3, 'Pelikan', '3003333333', 'ventas@pelikan.com', 'Cali'),
(4, 'Bic', '3004444444', 'ventas@bic.com', 'Barranquilla'),
(5, 'OffiExpress', '3005555555', 'ventas@offi.com', 'Bogotá');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id_rol` int(11) NOT NULL,
  `nombre_rol` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id_rol`, `nombre_rol`) VALUES
(1, 'Administrador'),
(2, 'Empleado'),
(3, 'Cliente');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id_usuario` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `correo` varchar(120) NOT NULL,
  `contraseña` varchar(255) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `telefono_secundario` varchar(20) DEFAULT NULL,
  `direccion` varchar(200) DEFAULT NULL,
  `id_rol` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id_usuario`, `nombre`, `apellido`, `correo`, `contraseña`, `telefono`, `telefono_secundario`, `direccion`, `id_rol`) VALUES
(1, 'Juan', 'Pérez', 'juan@gmail.com', '$2y$10$UWfFnFdz/550vHUaIFa63.lk8cCT9FWK4QMQdJUr7Ay26iVQjlys6', '3001111111', '3001111112', 'Bogotá', 1),
(2, 'Laura', 'Gómez', 'laura@gmail.com', '$2y$10$Zayd76cZKuPGoEP/NLnkjeZ8Vl0fEjhQ6eVSUTeq9EKjKpBvJcGqO', '3002222222', '3002222223', 'Medellín', 2),
(3, 'Carlos', 'Ruiz', 'carlos@gmail.com', '$2y$10$5R8Nj3qsrfVn260vAburnu/iU9MZoaduGf/bwNFf0tTbL0ZNCFA9e', '3003333333', '3003333334', 'Cali', 3),
(4, 'Andrea', 'Morales', 'andrea@gmail.com', '$2y$10$kfQK8rBrWkVThJOtcrecgeFcgg7xKsMjt8S7.HvhsMyTx83.NIaZG', '3004444444', '3004444445', 'Bogotá', 3),
(6, 'Pedro', 'Ramírez', 'pedro@gmail.com', '$2y$10$ziy9tC/HpUjv1erUggRG0OfQJs2mq/i8hVZvot61D17cGIrgtbqGi', '3009876543', '3009876544', 'Calle 20 #15-30', 2),
(7, 'CHECHO', 'CHOCHO', 'checho@gmail.com', '$2y$10$2PwYZGrb7ukdOjP..rFGve4E/ET.PQz0cZcjtM3FbF6.x5C8AWBAm', '78965425715', NULL, '', 3);

--
-- Disparadores `usuario`
--
DELIMITER $$
CREATE TRIGGER `tr_log_usuario` AFTER INSERT ON `usuario` FOR EACH ROW BEGIN

INSERT INTO logs
(
id_usuario,
tipo_accion,
fecha_movimiento
)

VALUES
(
NEW.id_usuario,
'Nuevo usuario registrado',
NOW()
);

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas`
--

CREATE TABLE `ventas` (
  `id_venta` int(11) NOT NULL,
  `id_pedido` int(11) DEFAULT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `fecha_venta` datetime DEFAULT NULL,
  `subtotal` decimal(10,2) DEFAULT NULL,
  `descuentos` decimal(10,2) DEFAULT NULL,
  `cantidad_productos` int(11) DEFAULT NULL,
  `total` decimal(10,2) DEFAULT NULL,
  `estado_pago` varchar(40) DEFAULT NULL,
  `numero_factura` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `ventas`
--

INSERT INTO `ventas` (`id_venta`, `id_pedido`, `id_usuario`, `fecha_venta`, `subtotal`, `descuentos`, `cantidad_productos`, `total`, `estado_pago`, `numero_factura`) VALUES
(1, 3, 3, '2026-08-04 15:48:32', 19500.00, 0.00, 3, 19500.00, 'Pagado', 'FAC-3'),
(2, 30, 1, '2026-08-06 14:37:41', 514000.00, 0.00, 152, 514000.00, 'Pagado', 'FAC-30');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_compras`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_compras` (
`id_compra` int(11)
,`nombre` varchar(120)
,`total` decimal(10,2)
,`fecha_compra` datetime
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_productos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_productos` (
`id_producto` int(11)
,`nombre` varchar(150)
,`nombre_categoria` varchar(100)
,`proveedor` varchar(120)
,`precio_compra` decimal(10,2)
,`precio_venta` decimal(10,2)
,`stock_actual` int(11)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_productos_mas_vendidos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_productos_mas_vendidos` (
`nombre` varchar(150)
,`vendidos` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_stock_bajo`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_stock_bajo` (
`id_producto` int(11)
,`id_proveedor` int(11)
,`nombre` varchar(150)
,`descripcion` varchar(500)
,`precio_compra` decimal(10,2)
,`precio_venta` decimal(10,2)
,`url_imagen` varchar(255)
,`stock_actual` int(11)
,`stock_minimo` int(11)
,`id_categoria` int(11)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_ventas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_ventas` (
`id_venta` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`total` decimal(10,2)
,`estado_pago` varchar(40)
,`numero_factura` varchar(100)
,`fecha_venta` datetime
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_compras`
--
DROP TABLE IF EXISTS `vw_compras`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_compras`  AS SELECT `c`.`id_compra` AS `id_compra`, `p`.`nombre` AS `nombre`, `c`.`total` AS `total`, `c`.`fecha_compra` AS `fecha_compra` FROM (`compras` `c` join `proovedores` `p` on(`c`.`id_proveedor` = `p`.`id_proovedores`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_productos`
--
DROP TABLE IF EXISTS `vw_productos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_productos`  AS SELECT `p`.`id_producto` AS `id_producto`, `p`.`nombre` AS `nombre`, `c`.`nombre_categoria` AS `nombre_categoria`, `pr`.`nombre` AS `proveedor`, `p`.`precio_compra` AS `precio_compra`, `p`.`precio_venta` AS `precio_venta`, `p`.`stock_actual` AS `stock_actual` FROM ((`producto` `p` join `categoria` `c` on(`p`.`id_categoria` = `c`.`id_categoria`)) join `proovedores` `pr` on(`p`.`id_proveedor` = `pr`.`id_proovedores`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_productos_mas_vendidos`
--
DROP TABLE IF EXISTS `vw_productos_mas_vendidos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_productos_mas_vendidos`  AS SELECT `p`.`nombre` AS `nombre`, sum(`dp`.`cantidad`) AS `vendidos` FROM (`producto` `p` join `detalles_pedido` `dp` on(`p`.`id_producto` = `dp`.`id_producto`)) GROUP BY `p`.`nombre` ORDER BY sum(`dp`.`cantidad`) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_stock_bajo`
--
DROP TABLE IF EXISTS `vw_stock_bajo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_stock_bajo`  AS SELECT `producto`.`id_producto` AS `id_producto`, `producto`.`id_proveedor` AS `id_proveedor`, `producto`.`nombre` AS `nombre`, `producto`.`descripcion` AS `descripcion`, `producto`.`precio_compra` AS `precio_compra`, `producto`.`precio_venta` AS `precio_venta`, `producto`.`url_imagen` AS `url_imagen`, `producto`.`stock_actual` AS `stock_actual`, `producto`.`stock_minimo` AS `stock_minimo`, `producto`.`id_categoria` AS `id_categoria` FROM `producto` WHERE `producto`.`stock_actual` <= `producto`.`stock_minimo` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_ventas`
--
DROP TABLE IF EXISTS `vw_ventas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_ventas`  AS SELECT `v`.`id_venta` AS `id_venta`, `u`.`nombre` AS `nombre`, `u`.`apellido` AS `apellido`, `v`.`total` AS `total`, `v`.`estado_pago` AS `estado_pago`, `v`.`numero_factura` AS `numero_factura`, `v`.`fecha_venta` AS `fecha_venta` FROM (`ventas` `v` join `usuario` `u` on(`v`.`id_usuario` = `u`.`id_usuario`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `carrito`
--
ALTER TABLE `carrito`
  ADD PRIMARY KEY (`id_carrito`),
  ADD KEY `id_usuario` (`id_usuario`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `categoria`
--
ALTER TABLE `categoria`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id_compra`),
  ADD KEY `id_proveedor` (`id_proveedor`),
  ADD KEY `fk_compras_usuario` (`id_usuario`);

--
-- Indices de la tabla `descuentos`
--
ALTER TABLE `descuentos`
  ADD PRIMARY KEY (`id_descuento`);

--
-- Indices de la tabla `detalles_compra`
--
ALTER TABLE `detalles_compra`
  ADD PRIMARY KEY (`id_detalle_compra`),
  ADD KEY `id_compra` (`id_compra`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `detalles_pedido`
--
ALTER TABLE `detalles_pedido`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `id_pedido` (`id_pedido`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `logs`
--
ALTER TABLE `logs`
  ADD PRIMARY KEY (`id_log`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `metodo_pago`
--
ALTER TABLE `metodo_pago`
  ADD PRIMARY KEY (`id_metodo_pago`);

--
-- Indices de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id_pedido`),
  ADD KEY `id_usuario` (`id_usuario`),
  ADD KEY `id_descuento` (`id_descuento`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`id_producto`),
  ADD KEY `fk_producto_proveedor` (`id_proveedor`),
  ADD KEY `fk_producto_categoria` (`id_categoria`);

--
-- Indices de la tabla `proovedores`
--
ALTER TABLE `proovedores`
  ADD PRIMARY KEY (`id_proovedores`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id_rol`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `correo` (`correo`),
  ADD KEY `id_rol` (`id_rol`);

--
-- Indices de la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD PRIMARY KEY (`id_venta`),
  ADD UNIQUE KEY `id_pedido` (`id_pedido`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `carrito`
--
ALTER TABLE `carrito`
  MODIFY `id_carrito` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `categoria`
--
ALTER TABLE `categoria`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `id_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `descuentos`
--
ALTER TABLE `descuentos`
  MODIFY `id_descuento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `detalles_compra`
--
ALTER TABLE `detalles_compra`
  MODIFY `id_detalle_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `detalles_pedido`
--
ALTER TABLE `detalles_pedido`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT de la tabla `logs`
--
ALTER TABLE `logs`
  MODIFY `id_log` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT de la tabla `metodo_pago`
--
ALTER TABLE `metodo_pago`
  MODIFY `id_metodo_pago` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id_pedido` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `proovedores`
--
ALTER TABLE `proovedores`
  MODIFY `id_proovedores` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id_rol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `ventas`
--
ALTER TABLE `ventas`
  MODIFY `id_venta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `carrito`
--
ALTER TABLE `carrito`
  ADD CONSTRAINT `carrito_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  ADD CONSTRAINT `carrito_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`);

--
-- Filtros para la tabla `compras`
--
ALTER TABLE `compras`
  ADD CONSTRAINT `compras_ibfk_1` FOREIGN KEY (`id_proveedor`) REFERENCES `proovedores` (`id_proovedores`),
  ADD CONSTRAINT `fk_compras_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

--
-- Filtros para la tabla `detalles_compra`
--
ALTER TABLE `detalles_compra`
  ADD CONSTRAINT `detalles_compra_ibfk_1` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id_compra`),
  ADD CONSTRAINT `detalles_compra_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`);

--
-- Filtros para la tabla `detalles_pedido`
--
ALTER TABLE `detalles_pedido`
  ADD CONSTRAINT `detalles_pedido_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`),
  ADD CONSTRAINT `detalles_pedido_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`);

--
-- Filtros para la tabla `logs`
--
ALTER TABLE `logs`
  ADD CONSTRAINT `logs_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

--
-- Filtros para la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD CONSTRAINT `pedidos_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  ADD CONSTRAINT `pedidos_ibfk_2` FOREIGN KEY (`id_descuento`) REFERENCES `descuentos` (`id_descuento`);

--
-- Filtros para la tabla `producto`
--
ALTER TABLE `producto`
  ADD CONSTRAINT `fk_producto_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `categoria` (`id_categoria`),
  ADD CONSTRAINT `fk_producto_proveedor` FOREIGN KEY (`id_proveedor`) REFERENCES `proovedores` (`id_proovedores`);

--
-- Filtros para la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `usuario_ibfk_1` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`);

--
-- Filtros para la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`),
  ADD CONSTRAINT `ventas_ibfk_2` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

DELIMITER $$
--
-- Eventos
--
CREATE DEFINER=`root`@`localhost` EVENT `ev_descuentos_vencidos` ON SCHEDULE EVERY 1 DAY STARTS '2026-08-04 15:45:35' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN

UPDATE descuentos

SET estado='Inactivo'

WHERE fecha_fin<CURDATE();

END$$

CREATE DEFINER=`root`@`localhost` EVENT `ev_log_diario` ON SCHEDULE EVERY 1 DAY STARTS '2026-08-04 15:45:41' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN

INSERT INTO logs
(
id_usuario,
tipo_accion,
fecha_movimiento
)

VALUES
(
NULL,
'Verificación automática del sistema',
NOW()
);

END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
