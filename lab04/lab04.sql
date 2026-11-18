-- Практическая работа № 4
-- Выполнила: Тубольцева Лада
-- Группа: ИНБО-20-23
-- Вариант: 6
-- Тема: Повторные покупатели

-- 1. Основной запрос: повторные покупатели.
-- Используем три таблицы: customers, orders, order_payments.
-- Считаем только доставленные заказы.

-- Кратность связей:
-- customers → orders по customer_id: 1:N.
-- orders → order_payments по order_id: 1:N.
-- После суммирования платежей получаем одну строку на заказ,
-- поэтому orders → payments_per_order: 1:0..1.
-- LEFT JOIN сохраняет заказы, для которых нет платежей.

WITH payments_per_order AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM olist.order_payments
    GROUP BY order_id
)
SELECT
    c.customer_unique_id,
    COUNT(*) AS orders_count,
    MIN(o.order_purchase_timestamp) AS first_purchase,
    MAX(o.order_purchase_timestamp) AS last_purchase,
    MAX(o.order_purchase_timestamp)
        - MIN(o.order_purchase_timestamp) AS time_between_purchases,
    SUM(COALESCE(p.total_payment, 0)) AS total_paid
FROM olist.customers AS c
JOIN olist.orders AS o
    ON o.customer_id = c.customer_id
LEFT JOIN payments_per_order AS p
    ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND c.customer_unique_id IS NOT NULL
GROUP BY c.customer_unique_id
HAVING COUNT(*) > 1
ORDER BY orders_count DESC, c.customer_unique_id;

-- 2. Антисоединение: заказы без платежей.
-- orders → order_payments: 1:N.
-- LEFT JOIN сохраняет все заказы.
-- WHERE оставляет только те, для которых платеж не найден.
-- Проверяем заказы со всеми статусами.

SELECT
    o.order_id,
    c.customer_unique_id,
    o.order_status,
    o.order_purchase_timestamp
FROM olist.orders AS o
JOIN olist.customers AS c
    ON c.customer_id = o.customer_id
LEFT JOIN olist.order_payments AS p
    ON p.order_id = o.order_id
WHERE p.order_id IS NULL
ORDER BY o.order_purchase_timestamp, o.order_id;


-- 3. Намеренно ошибочный JOIN: размножение платежей.
-- orders → order_items: 1:N.
-- orders → order_payments: 1:N.
-- Каждый платеж повторяется для каждой позиции заказа.
-- Сравниваем суммы на одном и том же наборе заказов.

WITH eligible_orders AS (
    SELECT o.order_id
    FROM olist.orders AS o
    WHERE EXISTS (
        SELECT 1
        FROM olist.order_items AS i
        WHERE i.order_id = o.order_id
    )
)
SELECT
    -- Правильная сумма: каждый платеж учитывается один раз.
    (
        SELECT SUM(p.payment_value)
        FROM eligible_orders AS o
        JOIN olist.order_payments AS p
            ON p.order_id = o.order_id
    ) AS correct_payment_sum,

    -- Ошибочная сумма после соединения товаров и платежей.
    SUM(p.payment_value) AS wrong_payment_sum,

    -- Количество строк после ошибочного соединения.
    COUNT(*) AS joined_rows,

    -- Реальное количество заказов с товарами и платежами.
    COUNT(DISTINCT o.order_id) AS orders_count
FROM eligible_orders AS o
JOIN olist.order_items AS i
    ON i.order_id = o.order_id
JOIN olist.order_payments AS p
    ON p.order_id = o.order_id;
    
    
-- 4. Исправленный JOIN с предварительной агрегацией.
-- В каждом CTE получаем одну строку на заказ.
-- orders → items_per_order: 1:0..1.
-- orders → payments_per_order: 1:0..1.
-- INNER JOIN оставляет заказы с товарами и платежами,
-- как в предыдущем ошибочном соединении.

WITH items_per_order AS (
    SELECT
        order_id,
        COUNT(*) AS items_count
    FROM olist.order_items
    GROUP BY order_id
),
payments_per_order AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM olist.order_payments
    GROUP BY order_id
)
SELECT
    SUM(p.total_payment) AS corrected_payment_sum,
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT o.order_id) AS orders_count
FROM olist.orders AS o
JOIN items_per_order AS i
    ON i.order_id = o.order_id
JOIN payments_per_order AS p
    ON p.order_id = o.order_id;


/*
5. Реляционная алгебра основного запроса.

Обозначения:
C — customers, O — orders, P — order_payments.
γ — группировка и агрегирование;
σ — отбор строк;
π — выбор столбцов;
⋈ — внутреннее соединение;
⟕ — левое внешнее соединение.

1. Суммируем платежи каждого заказа:
P1 = γ order_id; SUM(payment_value) → total_payment (P)

2. Соединяем клиентов, заказы и суммы платежей:
J = (C ⋈ C.customer_id = O.customer_id O)
    ⟕ O.order_id = P1.order_id P1

3. Оставляем доставленные заказы с известным покупателем:
F = σ order_status = 'delivered'
      AND customer_unique_id IS NOT NULL (J)

4. Группируем по customer_unique_id:
G = γ customer_unique_id;
      COUNT(*) → orders_count,
      MIN(order_purchase_timestamp) → first_purchase,
      MAX(order_purchase_timestamp) → last_purchase,
      SUM(COALESCE(total_payment, 0)) → total_paid (F)

5. Оставляем покупателей с несколькими заказами:
R = σ orders_count > 1 (G)

6. Формируем итоговые столбцы расширенной проекцией:
Result = π customer_unique_id, orders_count,
           first_purchase, last_purchase,
           (last_purchase - first_purchase)
               → time_between_purchases,
           total_paid (R)

Использована расширенная реляционная алгебра:
с группировкой, агрегатами и вычисляемыми столбцами.
Сортировка SQL задаёт порядок отображения результата.
*/