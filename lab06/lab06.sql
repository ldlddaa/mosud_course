-- Тубольцева Лада
-- Группа: ИНБО-20-23
-- Практическая работа № 6
-- Подзапросы и логика предикатов
-- Вариант 6
-- Задача: найти заказы, сумма платежей которых
-- превышает сумму стоимости товаров и доставки.

-- 1. Для первых 10 заказов отдельно вычисляем
-- сумму платежей и стоимость товаров с доставкой.

SELECT
    o.order_id,

    (
        SELECT SUM(op.payment_value)
        FROM olist.order_payments AS op
        WHERE op.order_id = o.order_id
    ) AS payments_total,

    (
        SELECT SUM(oi.price + oi.freight_value)
        FROM olist.order_items AS oi
        WHERE oi.order_id = o.order_id
    ) AS items_total

FROM olist.orders AS o
ORDER BY o.order_id
LIMIT 10;

-- 2. Основное решение: находим заказы,
-- где сумма платежей больше стоимости товаров с доставкой.

SELECT
    totals.order_id,
    totals.payments_total,
    totals.items_total
FROM (
    SELECT
        o.order_id,
        (
            SELECT SUM(op.payment_value)
            FROM olist.order_payments AS op
            WHERE op.order_id = o.order_id
        ) AS payments_total,
        (
            SELECT SUM(oi.price + oi.freight_value)
            FROM olist.order_items AS oi
            WHERE oi.order_id = o.order_id
        ) AS items_total
    FROM olist.orders AS o
) AS totals
WHERE totals.payments_total > totals.items_total
ORDER BY totals.order_id;


-- 3. Альтернативное решение через CTE и JOIN
-- с предварительным подсчётом сумм по каждому заказу.

WITH payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS payments_total
    FROM olist.order_payments
    GROUP BY order_id
),
items AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS items_total
    FROM olist.order_items
    GROUP BY order_id
)
SELECT
    o.order_id,
    p.payments_total,
    i.items_total
FROM olist.orders AS o
JOIN payments AS p ON p.order_id = o.order_id
JOIN items AS i ON i.order_id = o.order_id
WHERE p.payments_total > i.items_total
ORDER BY o.order_id;

-- 4. Проверка совпадения двух решений через EXCEPT в обе стороны.

WITH calculated AS (
    SELECT
        o.order_id,
        (
            SELECT SUM(op.payment_value)
            FROM olist.order_payments AS op
            WHERE op.order_id = o.order_id
        ) AS payments_total,
        (
            SELECT SUM(oi.price + oi.freight_value)
            FROM olist.order_items AS oi
            WHERE oi.order_id = o.order_id
        ) AS items_total
    FROM olist.orders AS o
),
main_result AS (
    SELECT order_id, payments_total, items_total
    FROM calculated
    WHERE payments_total > items_total
),
payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS payments_total
    FROM olist.order_payments
    GROUP BY order_id
),
items AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS items_total
    FROM olist.order_items
    GROUP BY order_id
),
alternative_result AS (
    SELECT
        o.order_id,
        p.payments_total,
        i.items_total
    FROM olist.orders AS o
    JOIN payments AS p ON p.order_id = o.order_id
    JOIN items AS i ON i.order_id = o.order_id
    WHERE p.payments_total > i.items_total
)
SELECT
    (
        SELECT COUNT(*)
        FROM (
            SELECT * FROM main_result
            EXCEPT
            SELECT * FROM alternative_result
        ) AS difference
    ) AS only_in_main,
    (
        SELECT COUNT(*)
        FROM (
            SELECT * FROM alternative_result
            EXCEPT
            SELECT * FROM main_result
        ) AS difference
    ) AS only_in_alternative;


-- 5. Демонстрация ANY.
-- Сумма платежей больше суммы товаров с доставкой.
-- Здесь подзапрос для ANY возвращает одно значение —
-- общую стоимость позиций текущего заказа.

WITH payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS payments_total
    FROM olist.order_payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    p.payments_total,
    (
        SELECT SUM(oi.price + oi.freight_value)
        FROM olist.order_items AS oi
        WHERE oi.order_id = o.order_id
    ) AS items_total
FROM olist.orders AS o
JOIN payments AS p ON p.order_id = o.order_id
WHERE p.payments_total > ANY (
    SELECT SUM(oi.price + oi.freight_value)
    FROM olist.order_items AS oi
    WHERE oi.order_id = o.order_id
)
ORDER BY o.order_id;