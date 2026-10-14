-- =====================================================================
-- Proyecto : RetailPro  -  Consultas SQL de negocio
-- Curso    : Data Analytics - Coderhouse - Modulo 4
-- Alumno   : Aranda, Mauro Nahuel
-- Motor    : SQL Server 2025 (SQL Server Management Studio 22)
-- Base     : Ventas_Tech_DB (creada en el Modulo 3)
-- =====================================================================

USE Ventas_Tech_DB;
GO

-- =====================================================================
-- CONSULTA 1 - Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- =====================================================================
SELECT
    MONTH(fecha_venta)                          AS mes,
    SUM(cantidad * precio_unitario)             AS total_facturado,
    COUNT(*)                                    AS cantidad_pedidos,
    SUM(cantidad * precio_unitario) / COUNT(*)  AS ticket_promedio
FROM ventas
GROUP BY MONTH(fecha_venta)
ORDER BY mes;
GO

-- =====================================================================
-- CONSULTA 2 - Ranking de productos (Top 5 por facturacion)
-- =====================================================================
SELECT TOP 5
    id_producto,
    SUM(cantidad)                    AS unidades_vendidas,
    SUM(cantidad * precio_unitario)  AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;
GO

-- =====================================================================
-- CONSULTA 3 - Clientes recurrentes (mas de un pedido)
-- =====================================================================
SELECT
    id_cliente,
    COUNT(*)                         AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)  AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;
GO

-- =====================================================================
-- CONSULTA 4 - Meses por encima o por debajo del promedio mensual
-- =====================================================================
SELECT
    MONTH(fecha_venta)               AS mes,
    SUM(cantidad * precio_unitario)  AS total_facturado,
    CASE
        WHEN SUM(cantidad * precio_unitario) >= (
                 SELECT AVG(total_mes)
                 FROM (
                     SELECT SUM(cantidad * precio_unitario) AS total_mes
                     FROM ventas
                     GROUP BY MONTH(fecha_venta)
                 ) AS totales_mensuales
             )
        THEN 'Por encima'
        ELSE 'Por debajo'
    END                              AS comparacion_promedio
FROM ventas
GROUP BY MONTH(fecha_venta)
ORDER BY mes;
GO

-- =====================================================================
-- HALLAZGOS
-- =====================================================================
-- 1. Toda la operacion registrada se concentra en un unico mes (marzo de
--    2024), con 6.444 de facturacion total, 10 pedidos y un ticket
--    promedio de 644,40. Por eso el analisis mensual devuelve una sola
--    fila y la comparacion contra el promedio no muestra variacion: no
--    hay con que comparar. Para que el analisis temporal tenga sentido,
--    la base necesita cargar al menos un par de meses mas.
--
-- 2. El producto 1 concentra 3.600 de facturacion, el 56 % del total,
--    vendiendo apenas 3 unidades. En el otro extremo, el producto 2
--    vendio 13 unidades (la mayor cantidad de toda la base) pero genero
--    solo 364, el 6 % del total. Volumen y facturacion no van juntos: un
--    ranking armado por unidades daria un resultado opuesto al de este.
--
-- 3. Los cinco clientes realizaron exactamente dos pedidos cada uno, por
--    lo que la frecuencia de compra no los distingue. Lo que si los
--    distingue es el monto: el cliente 1 gasto 2.640 y el cliente 4
--    gasto 510, una diferencia de cinco veces. Segmentar por cantidad de
--    pedidos seria inutil en esta base; hay que segmentar por facturacion.
-- =====================================================================
