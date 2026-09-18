-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 04-08-2026 a las 14:39:04
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
-- Base de datos: `colorinpapelin`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_venta` (IN `p_id_empleado` INT)   BEGIN
	INSERT INTO ventas
(
id_pedido, id_usuario, fecha_venta, subtotal, descuento, total, estado_pago, numero_factura)
VALUES
(
NOW(),
p_id_empleado,
0
);
SELECT LAST_INSERT_ID() AS Nmero_venta;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `carrito`
--

CREATE TABLE `carrito` (
  `id_carrito` int(10) NOT NULL,
  `id_usuario` int(10) NOT NULL,
  `fecha_creacion` datetime DEFAULT NULL,
  `id_producto` int(10) NOT NULL,
  `cantidad` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `carrito`
--

INSERT INTO `carrito` (`id_carrito`, `id_usuario`, `fecha_creacion`, `id_producto`, `cantidad`) VALUES
(1, 1, '2026-07-22 00:00:00', 1, 3),
(2, 2, '2026-07-14 00:00:00', 2, 1),
(3, 3, '2026-07-30 00:00:00', 3, 5);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria`
--

CREATE TABLE `categoria` (
  `id_categoria` int(10) NOT NULL,
  `nombre_categoria` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categoria`
--

INSERT INTO `categoria` (`id_categoria`, `nombre_categoria`) VALUES
(1, 'Útiles Escolares'),
(2, 'Papelería'),
(3, 'Oficina');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `id_compra` int(11) NOT NULL,
  `id_proveedor` int(11) NOT NULL,
  `fecha_compra` datetime DEFAULT current_timestamp(),
  `total` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `compras`
--

INSERT INTO `compras` (`id_compra`, `id_proveedor`, `fecha_compra`, `total`) VALUES
(1, 1, '2026-08-04 06:52:06', 50000.00),
(2, 1, '2026-08-04 07:22:27', 50000.00),
(3, 1, '2026-08-04 07:24:27', 50000.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `descuentos`
--

CREATE TABLE `descuentos` (
  `id_descuentos` int(10) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `estado` varchar(20) DEFAULT NULL,
  `porcentaje_descuento` decimal(5,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `descuentos`
--

INSERT INTO `descuentos` (`id_descuentos`, `nombre`, `fecha_inicio`, `fecha_fin`, `estado`, `porcentaje_descuento`) VALUES
(1, 'Regreso a Clases', '2026-01-10', '2026-02-28', 'Inactivo', 10.00),
(2, 'Cliente Frecuente', '2026-03-01', '2026-12-31', 'Inactivo', 15.00),
(3, 'Fin de Año', '2026-12-01', '2026-12-31', 'Inactivo', 20.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_compra`
--

CREATE TABLE `detalles_compra` (
  `id_detalle_compra` int(11) NOT NULL,
  `id_compra` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_compra` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalles_compra`
--

INSERT INTO `detalles_compra` (`id_detalle_compra`, `id_compra`, `id_producto`, `cantidad`, `precio_compra`) VALUES
(1, 1, 2, 50, 1000.00),
(2, 2, 2, 50, 1000.00),
(3, 2, 2, 50, 1000.00);

--
-- Disparadores `detalles_compra`
--
DELIMITER $$
CREATE TRIGGER `reabastecer_stock_compra` AFTER INSERT ON `detalles_compra` FOR EACH ROW BEGIN
    UPDATE producto 
    SET stock_actual = stock_actual + NEW.cantidad
    WHERE id_producto = NEW.id_producto;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_pedido`
--

CREATE TABLE `detalles_pedido` (
  `id_detalle_pedido` int(10) NOT NULL,
  `id_pedido` int(10) NOT NULL,
  `id_producto` int(10) NOT NULL,
  `cantidad` int(10) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `estado_pedido` varchar(50) DEFAULT NULL,
  `valor_total` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalles_pedido`
--

INSERT INTO `detalles_pedido` (`id_detalle_pedido`, `id_pedido`, `id_producto`, `cantidad`, `precio_unitario`, `estado_pedido`, `valor_total`) VALUES
(1, 1, 1, 3, 8500.00, 'Entregado', 25500.00),
(2, 2, 3, 1, 24000.00, 'En proceso', 24000.00),
(3, 3, 2, 20, 2000.00, 'Pendiente', 40000.00),
(13, 1, 2, 2, 2000.00, 'Pendiente', 4000.00),
(18, 9, 2, 5, 1500.00, NULL, 7500.00),
(20, 10, 2, 1, 1500.00, NULL, 1500.00),
(22, 18, 2, 3, 1500.00, NULL, 4500.00),
(23, 1, 3, 5, 2000.00, NULL, 10000.00),
(24, 19, 2, 3, 1500.00, NULL, 4500.00),
(25, 20, 2, 3, 1500.00, NULL, 4500.00),
(26, 21, 2, 3, 1500.00, NULL, 4500.00),
(27, 22, 2, 3, 1500.00, NULL, 4500.00),
(28, 23, 2, 3, 1500.00, NULL, 4500.00),
(29, 24, 2, 3, 1500.00, NULL, 4500.00),
(30, 25, 2, 3, 1500.00, NULL, 4500.00),
(31, 26, 2, 3, 1500.00, NULL, 4500.00),
(32, 27, 2, 3, 1500.00, NULL, 4500.00),
(33, 28, 2, 3, 1500.00, NULL, 4500.00),
(34, 29, 2, 3, 1500.00, NULL, 4500.00),
(35, 30, 2, 3, 1500.00, NULL, 4500.00),
(36, 31, 2, 3, 1500.00, NULL, 4500.00),
(37, 32, 2, 3, 1500.00, NULL, 4500.00);

--
-- Disparadores `detalles_pedido`
--
DELIMITER $$
CREATE TRIGGER `calcular_total_detalle` BEFORE INSERT ON `detalles_pedido` FOR EACH ROW BEGIN
SET NEW.valor_total = NEW.cantidad * NEW.precio_unitario;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `descontar_stock_pedido` AFTER INSERT ON `detalles_pedido` FOR EACH ROW BEGIN
UPDATE producto
SET stock_actual = stock_actual - NEW.cantidad
WHERE id_producto = NEW.id_producto;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `validar_stock_dispoible` BEFORE INSERT ON `detalles_pedido` FOR EACH ROW BEGIN
DECLARE stock_disponible INT;
SELECT stock_actual INTO stock_disponible
FROM producto
WHERE id_producto = NEW.id_producto;
IF NEW.cantidad > stock_disponible THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'ERROR: No hay stock para cubrir este pedido.';
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs`
--

CREATE TABLE `logs` (
  `id_log` int(10) NOT NULL,
  `id_usuario` int(10) NOT NULL,
  `tipo_accion` varchar(100) NOT NULL,
  `fecha_movimiento` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `logs`
--

INSERT INTO `logs` (`id_log`, `id_usuario`, `tipo_accion`, `fecha_movimiento`) VALUES
(1, 1, 'Inicio de sesión', '2026-07-01 08:15:00'),
(2, 2, 'Registro de pedido', '2026-07-02 10:30:00'),
(3, 3, 'Cierre de sesión', '2026-07-03 17:45:00'),
(13, 1, 'Alerta: El producto \"Resma Carta Reprograf\" alcanzo el stock minimo. Quedan 5 unidades.', '2026-08-02 19:47:58'),
(14, 12, 'Registro de nuevo usuario', '2026-08-02 20:01:05'),
(15, 12, 'Actualizacion de datos del usuario', '2026-08-02 20:01:05'),
(16, 12, 'Actualizacion de datos del usuario', '2026-08-02 20:01:22'),
(17, 4, 'Venta registrada exitosamente - Factura N°: FACT-9', '2026-08-02 20:16:44'),
(18, 14, 'Registro de nuevo usuario', '2026-08-02 20:21:28'),
(19, 14, 'Actualizacion de datos del usuario', '2026-08-02 20:21:28'),
(20, 1, 'Alerta: El producto \"Esfero Kilométrico Azul\" alcanzo el stock minimo. Quedan 2 unidades.', '2026-08-02 20:28:46'),
(21, 4, 'Venta registrada exitosamente - Factura N°: FACT-TEST-10', '2026-08-02 20:33:10'),
(22, 4, 'Venta registrada exitosamente - Factura N°: FACT-DESC-1', '2026-08-02 20:36:08'),
(23, 4, 'Venta registrada exitosamente - Factura N°: FACT-DESC-100', '2026-08-02 20:37:29'),
(24, 4, 'Venta registrada exitosamente - Factura N°: FACT-DESC-200', '2026-08-02 20:52:36'),
(25, 4, 'Venta registrada exitosamente - Factura N°: FACT-TEST-FINAL', '2026-08-02 20:53:45'),
(26, 4, 'Venta registrada exitosamente - Factura N°: FACT-CARRITO-100', '2026-08-02 20:54:20'),
(27, 15, 'Registro de nuevo usuario', '2026-08-02 21:05:23'),
(28, 21, 'Registro de nuevo usuario', '2026-08-02 21:08:24'),
(29, 4, 'Venta registrada exitosamente - Factura N°: FACT-VENTA-REFLEJO-1', '2026-08-03 09:07:39'),
(30, 4, 'Venta registrada exitosamente - Factura N°: FACT-001', '2026-08-03 09:30:43'),
(31, 4, 'Venta registrada exitosamente - Factura N°: FACT-002', '2026-08-03 09:32:15'),
(32, 4, 'Venta registrada exitosamente - Factura N°: FACT-003', '2026-08-03 09:33:12'),
(33, 4, 'Venta registrada exitosamente - Factura N°: FACT-004', '2026-08-03 09:41:44'),
(34, 4, 'Venta registrada exitosamente - Factura N°: FACT-114226', '2026-08-03 09:42:32'),
(35, 4, 'Venta registrada exitosamente - Factura N°: FACT-1989', '2026-08-03 09:46:44'),
(36, 4, 'Venta registrada exitosamente - Factura N°: FACT-9473', '2026-08-03 09:51:30'),
(37, 22, 'Registro de nuevo usuario', '2026-08-04 06:43:09'),
(38, 4, 'Venta registrada exitosamente - Factura N°: FACT-4185', '2026-08-04 07:27:17'),
(39, 4, 'Venta registrada exitosamente - Factura N°: FACT-44', '2026-08-04 07:28:27');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `metodo_pago`
--

CREATE TABLE `metodo_pago` (
  `id_metodo` int(10) NOT NULL,
  `nombre_metodo` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `metodo_pago`
--

INSERT INTO `metodo_pago` (`id_metodo`, `nombre_metodo`) VALUES
(1, 'Efectivo'),
(2, 'Nequi');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos`
--

CREATE TABLE `pedidos` (
  `id_pedido` int(10) NOT NULL,
  `id_usuario` int(10) NOT NULL,
  `fecha_pedido` datetime DEFAULT NULL,
  `estado` int(10) NOT NULL,
  `id_metodo` int(10) NOT NULL,
  `comprobante_pago_url` varchar(255) DEFAULT NULL,
  `direccion_envio` varchar(255) NOT NULL,
  `telefono_envio` varchar(20) NOT NULL,
  `id_descuento` int(10) DEFAULT NULL,
  `total_venta` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pedidos`
--

INSERT INTO `pedidos` (`id_pedido`, `id_usuario`, `fecha_pedido`, `estado`, `id_metodo`, `comprobante_pago_url`, `direccion_envio`, `telefono_envio`, `id_descuento`, `total_venta`) VALUES
(1, 1, '2026-07-01 00:00:00', 1, 1, 'comprobante1.jpg', 'Calle 53 #30-25, Bogotá', '3104567890', 1, 25500.00),
(2, 2, '2026-07-02 00:00:00', 1, 2, 'comprobante2.jpg', 'Carrera 15 #72-40, Bogotá', '3116789012', 2, 24000.00),
(3, 3, '2026-07-03 00:00:00', 1, 1, 'comprobante3.jpg', 'Avenida Boyacá #45-67, Bogotá', '3128901234', 3, 40000.00),
(5, 5, '2026-08-02 19:39:56', 1, 1, NULL, 'Calle 100 #20-30', '3001112233', 2, 50000.00),
(9, 4, '2026-08-02 20:16:44', 1, 1, NULL, 'Calle Principal #123', '3001234567', NULL, 15000.00),
(10, 4, '2026-08-02 20:18:20', 1, 1, NULL, 'Calle Secundaria #456', '3001234567', NULL, 3000.00),
(11, 4, '2026-08-02 20:36:08', 1, 1, NULL, 'Calle Prueba 123', '3000000000', 1, 1500.00),
(12, 4, '2026-08-02 20:36:26', 1, 1, NULL, 'Calle Prueba 123', '3000000000', 1, 1500.00),
(13, 4, '2026-08-02 20:36:34', 1, 1, NULL, 'Calle Prueba 123', '3000000000', 1, 1500.00),
(14, 4, '2026-08-02 20:37:29', 1, 1, NULL, 'Calle Prueba 123', '3000000000', 1, 1500.00),
(15, 4, '2026-08-02 20:52:36', 1, 1, NULL, 'Calle Prueba 123', '3000000000', 1, 1500.00),
(16, 4, '2026-08-02 20:53:45', 1, 1, NULL, 'Calle Prueba', '3000000000', NULL, 1500.00),
(17, 4, '2026-08-02 20:54:20', 1, 1, NULL, 'Calle Prueba Final', '3000000000', NULL, 1500.00),
(18, 4, '2026-08-03 08:08:28', 1, 1, NULL, 'Calle Venta Test', '3000000000', NULL, 4500.00),
(19, 4, '2026-08-03 08:57:16', 1, 1, NULL, 'Calle Venta Test', '3000000000', NULL, 4500.00),
(20, 4, '2026-08-03 09:07:02', 1, 1, NULL, 'Calle Venta Test', '3000000000', NULL, 4500.00),
(21, 4, '2026-08-03 09:07:38', 1, 1, NULL, 'Calle Venta Completa', '3000000000', NULL, 4500.00),
(22, 4, '2026-08-03 09:30:42', 1, 1, NULL, 'Venta en Local', '3000000000', NULL, 4500.00),
(23, 4, '2026-08-03 09:32:15', 1, 1, NULL, 'Calle Venta Cantidades', '3000000000', NULL, 4500.00),
(24, 4, '2026-08-03 09:33:10', 1, 1, NULL, 'Venta Mostrador', '3000000000', NULL, 4500.00),
(25, 4, '2026-08-03 09:40:07', 1, 1, NULL, 'Venta Mostrador', '3000000000', NULL, 4500.00),
(26, 4, '2026-08-03 09:42:32', 1, 1, NULL, 'Venta Directa', '3000000000', NULL, 4500.00),
(27, 4, '2026-08-03 09:45:14', 1, 1, NULL, 'Local', '3000000000', NULL, 4500.00),
(28, 4, '2026-08-03 09:45:25', 1, 1, NULL, 'Local', '3000000000', NULL, 4500.00),
(29, 4, '2026-08-03 09:46:43', 1, 1, NULL, 'Local', '3000000000', NULL, 4500.00),
(30, 4, '2026-08-03 09:51:30', 1, 1, NULL, 'Local', '3000000000', NULL, 4500.00),
(31, 4, '2026-08-04 07:27:17', 1, 1, NULL, 'Venta Directa', '3000000000', NULL, 4500.00),
(32, 4, '2026-08-04 07:28:10', 1, 1, NULL, 'Venta Directa', '3000000000', NULL, 4500.00);

--
-- Disparadores `pedidos`
--
DELIMITER $$
CREATE TRIGGER `actualizar_descuentos` AFTER INSERT ON `pedidos` FOR EACH ROW BEGIN
IF NEW.id_descuento IS NOT NULL THEN
UPDATE descuentos
SET estado = 'Inactivo'
WHERE id_descuentos = NEW.id_descuento;
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `id_producto` int(10) NOT NULL,
  `id_proveedor` int(10) DEFAULT NULL,
  `nombre` varchar(150) NOT NULL,
  `descripcion` varchar(500) DEFAULT NULL,
  `precio_compra` decimal(10,2) NOT NULL,
  `precio_venta` decimal(10,2) NOT NULL,
  `url_imagen` varchar(255) DEFAULT NULL,
  `stock_actual` int(10) DEFAULT NULL,
  `stock_minimo` int(10) DEFAULT NULL,
  `id_categoria` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`id_producto`, `id_proveedor`, `nombre`, `descripcion`, `precio_compra`, `precio_venta`, `url_imagen`, `stock_actual`, `stock_minimo`, `id_categoria`) VALUES
(1, 1, 'Cuaderno Norma 100 hojas', 'Cuaderno cuadriculado', 6500.00, 8500.00, 'cuaderno.jpg', 120, 20, 1),
(2, 2, 'Esfero Kilométrico Azul', 'Bolígrafo tinta azul', 1200.00, 2000.00, 'esfero.jpg', 1105, 50, 2),
(3, 3, 'Resma Carta Reprograf', 'Resma de papel carta x500 hojas', 18000.00, 24000.00, 'resma.jpg', 0, 10, 3);

--
-- Disparadores `producto`
--
DELIMITER $$
CREATE TRIGGER `Alerta_stock_bajo` AFTER UPDATE ON `producto` FOR EACH ROW BEGIN
    IF NEW.stock_actual <= NEW.stock_minimo AND OLD.stock_actual > OLD.stock_minimo THEN
        INSERT INTO logs(id_usuario, tipo_accion, fecha_movimiento)
        VALUES (
            1,
            CONCAT('Alerta: El producto "', NEW.nombre, '" alcanzo el stock minimo. Quedan ', NEW.stock_actual, ' unidades.'),
            NOW()
        );
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `validar_valores_positivos_producto` BEFORE INSERT ON `producto` FOR EACH ROW BEGIN
IF NEW.precio_compra < 0 OR NEW.precio_venta < 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'ERROR: Los precios no pueden ser valores negativos.';
ELSEIF NEW.stock_actual < 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'ERROR: El stock actual no puede ser negativo.';
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proovedores`
--

CREATE TABLE `proovedores` (
  `id_proveedores` int(10) NOT NULL,
  `nombre_empresa` varchar(150) NOT NULL,
  `nombre_contacto` varchar(100) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `correo` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `proovedores`
--

INSERT INTO `proovedores` (`id_proveedores`, `nombre_empresa`, `nombre_contacto`, `telefono`, `correo`) VALUES
(1, 'Papeles Nacionales S.A.S.', 'Andrés Gómez', '3104567890', 'ventas@papelesnacionales.com'),
(2, 'Distribuidora Escolar Bogotá', 'Laura Pérez', '3115678901', 'contacto@distribuidoraescolar.com'),
(3, 'Suministros Capital S.A.S.', 'Carlos Ramírez', '3126789012', 'pedidos@suministroscapital.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id_rol` int(10) NOT NULL,
  `nombre_rol` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id_rol`, `nombre_rol`) VALUES
(1, 'Administrador'),
(2, 'Cliente'),
(3, 'Empleado');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id_usuario` int(10) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `correo` varchar(150) NOT NULL,
  `contraseña` varchar(255) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `telefono_secundario` varchar(20) DEFAULT NULL,
  `id_rol` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id_usuario`, `nombre`, `apellido`, `correo`, `contraseña`, `telefono`, `telefono_secundario`, `id_rol`) VALUES
(1, 'Juan', 'Rodríguez', 'juan.rodriguez@gmail.com', '1234', '3104567890', '3205678901', 1),
(2, 'María', 'González', 'maria.gonzalez@gmail.com', '1234', '3116789012', '3217890123', 2),
(3, 'Carlos', 'Martínez', 'carlos.martinez@gmail.com', '1234', '3128901234', '3229012345', 3),
(4, 'Camilo', 'Rojas', 'camilo.rojas@gmail.com', '123456', '3001234567', NULL, 2),
(5, 'Prueba', 'Descuento', 'prueba.desc@gmail.com', '1234', '3001112233', NULL, 2),
(7, 'Prueba', 'Logs', 'usuario.logs@gmail.com', '1234', '3220001122', NULL, 2),
(9, 'Camila', 'Rojas', 'camila.prueba2026@gmail.com', '1234', '3118887766', NULL, 2),
(12, 'Felipe', 'Torres', 'felipe.prueba2026@gmail.com', '1234', '3159998800', NULL, 2),
(14, 'Prueba', 'Triggers', 'prueba.triggers@gmail.com', '123456', '3118888888', NULL, 1),
(15, 'nicolas', 'gomez', 'nismad@gmail.com', '568', '3205896547', NULL, 2),
(21, 'NICOLAS', 'GOMEZ', 'NISISI@GMAIL.COM', '123', '3205789654', 'NULL', 1),
(22, 'CLIENTE', 'PRESENCIAL', 'CLIENTEPRE@GMAIL.COM', '124567', '3205746821', 'NULL', 1);

--
-- Disparadores `usuario`
--
DELIMITER $$
CREATE TRIGGER `log_actualizacion_usuario` AFTER UPDATE ON `usuario` FOR EACH ROW BEGIN
    INSERT INTO logs (id_usuario, tipo_accion, fecha_movimiento)
    VALUES (NEW.id_usuario, 'Actualizacion de datos del usuario', NOW());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `nuevo_usuario_log` AFTER INSERT ON `usuario` FOR EACH ROW BEGIN
    INSERT INTO logs (id_usuario, tipo_accion, fecha_movimiento)
    VALUES (NEW.id_usuario, 'Registro de nuevo usuario', NOW());
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas`
--

CREATE TABLE `ventas` (
  `id_venta` int(10) NOT NULL,
  `id_pedido` int(10) NOT NULL,
  `id_usuario` int(10) NOT NULL,
  `fecha_venta` datetime NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `descuentos` decimal(10,2) DEFAULT NULL,
  `cantidad_productos` int(11) NOT NULL DEFAULT 0,
  `total` decimal(10,2) NOT NULL,
  `estado_pago` varchar(50) NOT NULL,
  `numero_factura` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `ventas`
--

INSERT INTO `ventas` (`id_venta`, `id_pedido`, `id_usuario`, `fecha_venta`, `subtotal`, `descuentos`, `cantidad_productos`, `total`, `estado_pago`, `numero_factura`) VALUES
(1, 1, 1, '2026-07-01 00:00:00', 25500.00, 2550.00, 0, 22950.00, 'Pagado', 'FAC-001'),
(2, 2, 1, '2026-07-02 00:00:00', 24000.00, 2400.00, 0, 21600.00, 'Pagado', 'FAC-002'),
(3, 3, 1, '2026-07-03 00:00:00', 40000.00, 4000.00, 0, 36000.00, 'Pendiente', 'FAC-003'),
(9, 9, 4, '2026-08-02 20:16:44', 7500.00, 0.00, 0, 7500.00, 'Pagado', 'FACT-9'),
(10, 10, 4, '2026-08-02 20:33:10', 1500.00, 0.00, 0, 1500.00, 'Pagado', 'FACT-TEST-10'),
(11, 11, 4, '2026-08-02 20:36:08', 1500.00, 0.00, 0, 1500.00, 'Pagado', 'FACT-DESC-1'),
(14, 14, 4, '2026-08-02 20:37:29', 1500.00, 0.00, 0, 1500.00, 'Pagado', 'FACT-DESC-100'),
(15, 15, 4, '2026-08-02 20:52:36', 1500.00, 0.00, 0, 1500.00, 'Pagado', 'FACT-DESC-200'),
(16, 16, 4, '2026-08-02 20:53:45', 1500.00, 0.00, 0, 1500.00, 'Pagado', 'FACT-TEST-FINAL'),
(17, 17, 4, '2026-08-02 20:54:20', 1500.00, 0.00, 0, 1500.00, 'Pagado', 'FACT-CARRITO-100'),
(18, 21, 4, '2026-08-03 09:07:39', 4500.00, 0.00, 0, 4500.00, 'Pagado', 'FACT-VENTA-REFLEJO-1'),
(19, 22, 4, '2026-08-03 09:30:43', 4500.00, 0.00, 0, 4500.00, 'Pagado', 'FACT-001'),
(20, 23, 4, '2026-08-03 09:32:15', 4500.00, 0.00, 3, 4500.00, 'Pagado', 'FACT-002'),
(21, 24, 4, '2026-08-03 09:33:12', 4500.00, 0.00, 3, 4500.00, 'Pagado', 'FACT-003'),
(23, 25, 4, '2026-08-03 09:41:44', 4500.00, 0.00, 3, 4500.00, 'Pagado', 'FACT-004'),
(24, 26, 4, '2026-08-03 09:42:32', 4500.00, 0.00, 3, 4500.00, 'Pagado', 'FACT-114226'),
(27, 29, 4, '2026-08-03 09:46:44', 4500.00, 0.00, 3, 4500.00, 'Pagado', 'FACT-1989'),
(28, 30, 4, '2026-08-03 09:51:30', 4500.00, 0.00, 3, 4500.00, 'Pagado', 'FACT-9473'),
(29, 31, 4, '2026-08-04 07:27:17', 4500.00, 0.00, 3, 4500.00, 'Pagado', 'FACT-4185'),
(30, 32, 4, '2026-08-04 07:28:27', 4500.00, 0.00, 3, 4500.00, 'Pagado', 'FACT-44');

--
-- Disparadores `ventas`
--
DELIMITER $$
CREATE TRIGGER `calcular_cantidad_total_venta` BEFORE INSERT ON `ventas` FOR EACH ROW BEGIN
    DECLARE total_articulos INT;
    
    
    SELECT COALESCE(SUM(cantidad), 0) INTO total_articulos
    FROM detalles_pedido
    WHERE id_pedido = NEW.id_pedido;
    
    
    SET NEW.cantidad_productos = total_articulos;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `log_nueva_venta` AFTER INSERT ON `ventas` FOR EACH ROW BEGIN
    INSERT INTO logs (id_usuario, tipo_accion, fecha_movimiento)
    VALUES (
        NEW.id_usuario, 
        CONCAT('Venta registrada exitosamente - Factura N°: ', COALESCE(NEW.numero_factura, NEW.id_venta)), 
        NOW()
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `vaciar_carrito` AFTER INSERT ON `ventas` FOR EACH ROW BEGIN
DELETE FROM carrito
WHERE id_usuario = NEW.id_usuario;
END
$$
DELIMITER ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `carrito`
--
ALTER TABLE `carrito`
  ADD PRIMARY KEY (`id_carrito`),
  ADD UNIQUE KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `categoria`
--
ALTER TABLE `categoria`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id_compra`);

--
-- Indices de la tabla `descuentos`
--
ALTER TABLE `descuentos`
  ADD PRIMARY KEY (`id_descuentos`);

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
  ADD PRIMARY KEY (`id_detalle_pedido`),
  ADD UNIQUE KEY `id_pedido` (`id_pedido`,`id_producto`),
  ADD KEY `fl_asd` (`id_producto`);

--
-- Indices de la tabla `logs`
--
ALTER TABLE `logs`
  ADD PRIMARY KEY (`id_log`),
  ADD KEY `zxcas` (`id_usuario`);

--
-- Indices de la tabla `metodo_pago`
--
ALTER TABLE `metodo_pago`
  ADD PRIMARY KEY (`id_metodo`);

--
-- Indices de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id_pedido`),
  ADD KEY `hgh` (`id_metodo`),
  ADD KEY `jhjj` (`id_descuento`),
  ADD KEY `fk_pedidos_usuario` (`id_usuario`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`id_producto`),
  ADD UNIQUE KEY `id_proveedor` (`id_proveedor`),
  ADD KEY `fk_producto_categoria` (`id_categoria`);

--
-- Indices de la tabla `proovedores`
--
ALTER TABLE `proovedores`
  ADD PRIMARY KEY (`id_proveedores`);

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
  ADD KEY `idx_id_rol` (`id_rol`);

--
-- Indices de la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD PRIMARY KEY (`id_venta`),
  ADD UNIQUE KEY `id_pedido` (`id_pedido`),
  ADD UNIQUE KEY `numero_factura` (`numero_factura`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `carrito`
--
ALTER TABLE `carrito`
  MODIFY `id_carrito` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `categoria`
--
ALTER TABLE `categoria`
  MODIFY `id_categoria` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `id_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `descuentos`
--
ALTER TABLE `descuentos`
  MODIFY `id_descuentos` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `detalles_compra`
--
ALTER TABLE `detalles_compra`
  MODIFY `id_detalle_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `detalles_pedido`
--
ALTER TABLE `detalles_pedido`
  MODIFY `id_detalle_pedido` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT de la tabla `logs`
--
ALTER TABLE `logs`
  MODIFY `id_log` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT de la tabla `metodo_pago`
--
ALTER TABLE `metodo_pago`
  MODIFY `id_metodo` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id_pedido` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `id_producto` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `proovedores`
--
ALTER TABLE `proovedores`
  MODIFY `id_proveedores` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id_usuario` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT de la tabla `ventas`
--
ALTER TABLE `ventas`
  MODIFY `id_venta` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `carrito`
--
ALTER TABLE `carrito`
  ADD CONSTRAINT `fk_carrito_producto` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`);

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
  ADD CONSTRAINT `fk_de_` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`),
  ADD CONSTRAINT `fl_asd` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`);

--
-- Filtros para la tabla `logs`
--
ALTER TABLE `logs`
  ADD CONSTRAINT `zxcas` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

--
-- Filtros para la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD CONSTRAINT `fk_pedidos_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  ADD CONSTRAINT `hgh` FOREIGN KEY (`id_metodo`) REFERENCES `metodo_pago` (`id_metodo`),
  ADD CONSTRAINT `jhjj` FOREIGN KEY (`id_descuento`) REFERENCES `descuentos` (`id_descuentos`);

--
-- Filtros para la tabla `producto`
--
ALTER TABLE `producto`
  ADD CONSTRAINT `dsdsd` FOREIGN KEY (`id_proveedor`) REFERENCES `proovedores` (`id_proveedores`),
  ADD CONSTRAINT `fk_producto_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `categoria` (`id_categoria`);

--
-- Filtros para la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `re_us_rol` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`);

--
-- Filtros para la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD CONSTRAINT `erer` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`),
  ADD CONSTRAINT `fk_ventas_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
