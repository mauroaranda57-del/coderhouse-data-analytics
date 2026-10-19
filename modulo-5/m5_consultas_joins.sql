-- =====================================================================
-- Proyecto : RetailPro  -  Consultas con JOINs
-- Curso    : Data Analytics - Coderhouse - Modulo 5
-- Alumno   : Aranda, Mauro Nahuel
-- Motor    : SQL Server 2025 (SQL Server Management Studio 22)
-- Base     : Ventas_Tech_DB (creada en el Modulo 3)
-- =====================================================================

USE Ventas_Tech_DB;
GO

-- =====================================================================
-- CONSULTA 1 - Vista base del proyecto (INNER JOIN)
-- Proposito: unificar en una sola fila la venta con el nombre del
-- cliente, su ciudad, el producto y su categoria. Es la fuente de datos
-- que se conecta a Power BI: 'ciudad' y 'categoria' son las columnas
-- para agrupar y filtrar el dashboard.
-- =====================================================================
SELECT
    v.id_venta,
    v.fecha_venta,
    v.id_cliente,
    c.nombre                AS nombre_cliente,
    c.ciudad,
    p.nombre_producto,
    cat.nombre_categoria    AS categoria,
    v.cantidad,
    v.precio_unitario,
    CAST(v.cantidad * v.precio_unitario AS DECIMAL(12,2)) AS total_venta
FROM ventas v
INNER JOIN clientes   c   ON v.id_cliente   = c.id_cliente
INNER JOIN productos  p   ON v.id_producto  = p.id_producto
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta;
GO
-- Hallazgo: las 10 ventas quedan enriquecidas con ciudad y categoria.
-- Computacion concentra 4.950 de los 6.444 facturados (77 %) con solo
-- dos productos (Laptop Pro 15 y Monitor 4K 27), mientras que las otras
-- tres categorias juntas aportan el 23 % restante. El negocio depende
-- hoy de una sola categoria.

-- =====================================================================
-- CONSULTA 2 - Clientes sin ventas (LEFT JOIN)
-- Proposito: detectar clientes registrados que nunca compraron, para
-- que CRM los contacte.
-- =====================================================================
SELECT
    c.id_cliente,
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_registro;
GO
-- Hallazgo: 2 de los 7 clientes registrados (29 %) nunca compraron:
-- Diego Fernandez y Sofia Herrera. Los dos se dieron de alta el 20 y el
-- 25 de marzo, es decir despues de la ultima venta registrada (15 de
-- marzo). Para CRM no son clientes perdidos sino altas recientes que
-- todavia no concretaron la primera compra: corresponde una accion de
-- bienvenida, no una de recuperacion.

-- =====================================================================
-- CONSULTA 3 - Productos sin ventas (LEFT JOIN)
-- Proposito: identificar articulos del catalogo sin movimiento, para
-- que el area de producto decida si los impulsa o los discontinua.
-- =====================================================================
SELECT
    p.id_producto,
    p.nombre_producto,
    cat.nombre_categoria AS categoria,
    p.precio
FROM productos p
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
LEFT  JOIN ventas     v   ON p.id_producto  = v.id_producto
WHERE v.id_venta IS NULL
ORDER BY p.precio DESC;
GO
-- Hallazgo: 2 de los 8 productos del catalogo (25 %) no registran
-- ninguna venta: Parlante Bluetooth (Audio, 85) y Webcam HD 1080
-- (Accesorios, 65). Son las dos ultimas altas del catalogo, asi que la
-- falta de movimiento puede deberse a que recien se incorporaron. El
-- caso a vigilar es el Parlante: Audio ya es la categoria de menor
-- facturacion (360, el 6 % del total), de modo que el area de producto
-- estaria sumando articulos a la linea que menos vende.

-- =====================================================================
-- CONSULTA 4 - Consolidado por origen (UNION ALL)
-- Proposito: comparar el desempeno de las dos quincenas de marzo. La
-- columna 'origen' no existe en las tablas: se genera como valor
-- literal dentro de cada SELECT. Se usa UNION ALL y no UNION para que
-- ninguna venta se descarte por coincidir con otra en todos sus valores.
-- =====================================================================
SELECT
    origen,
    COUNT(*)   AS cantidad_ventas,
    SUM(total) AS total_origen
FROM (
    SELECT
        fecha_venta,
        CAST(cantidad * precio_unitario AS DECIMAL(12,2)) AS total,
        'Primera quincena'  AS origen
    FROM ventas
    WHERE fecha_venta <= '2024-03-10'

    UNION ALL

    SELECT
        fecha_venta,
        CAST(cantidad * precio_unitario AS DECIMAL(12,2)) AS total,
        'Segunda quincena'  AS origen
    FROM ventas
    WHERE fecha_venta > '2024-03-10'
) AS consolidado
GROUP BY origen
ORDER BY total_origen DESC;
GO
-- Hallazgo: la primera quincena facturo 3.620 y la segunda 2.824, una
-- caida de 796 (22 %). Lo relevante es que las dos tuvieron exactamente
-- 5 ventas: no se vendio menos veces, se vendio mas barato. El ticket
-- promedio paso de 724,00 a 564,80. La causa hay que buscarla en el mix
-- de productos, no en la cantidad de operaciones.
-- =====================================================================
