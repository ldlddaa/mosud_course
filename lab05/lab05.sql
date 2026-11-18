-- Тубольцева Лада
-- Группа: ИНБО-20-23
-- Практическая работа № 5
-- Вариант 6: PA, AM, RO

-- 1. Категории, проданные во всех трёх штатах.
-- Реализация через двойной NOT EXISTS.
-- Учитываем только доставленные заказы.
-- Исключаем NULL, пустые названия и названия из пробелов.

WITH target_states(customer_state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),
categories AS (
    SELECT DISTINCT product_category_name
    FROM olist.products
    WHERE product_category_name IS NOT NULL
      AND TRIM(product_category_name) <> ''
),
category_sales AS (
    SELECT DISTINCT
        p.product_category_name,
        c.customer_state
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON c.customer_id = o.customer_id
    JOIN olist.order_items AS oi
        ON oi.order_id = o.order_id
    JOIN olist.products AS p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
      AND TRIM(p.product_category_name) <> ''
)
SELECT cat.product_category_name
FROM categories AS cat
WHERE NOT EXISTS (
    SELECT 1
    FROM target_states AS ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM category_sales AS cs
        WHERE cs.product_category_name = cat.product_category_name
          AND cs.customer_state = ts.customer_state
    )
)
ORDER BY cat.product_category_name;


-- 2. Те же категории через GROUP BY и HAVING.
-- Число охваченных штатов должно равняться числу штатов в target_states.

WITH target_states(customer_state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),
categories AS (
    SELECT DISTINCT product_category_name
    FROM olist.products
    WHERE product_category_name IS NOT NULL
      AND TRIM(product_category_name) <> ''
),
category_sales AS (
    SELECT DISTINCT
        p.product_category_name,
        c.customer_state
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON c.customer_id = o.customer_id
    JOIN olist.order_items AS oi
        ON oi.order_id = o.order_id
    JOIN olist.products AS p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
      AND TRIM(p.product_category_name) <> ''
)
SELECT cat.product_category_name
FROM categories AS cat
LEFT JOIN category_sales AS cs
    ON cs.product_category_name = cat.product_category_name
   AND cs.customer_state IN (
       SELECT customer_state
       FROM target_states
   )
GROUP BY cat.product_category_name
HAVING COUNT(DISTINCT cs.customer_state) = (
    SELECT COUNT(*)
    FROM target_states
)
ORDER BY cat.product_category_name;


-- 3. Те же категории через EXCEPT и NOT EXISTS.
-- Не должно остаться обязательных штатов без продажи категории.

WITH target_states(customer_state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),
categories AS (
    SELECT DISTINCT product_category_name
    FROM olist.products
    WHERE product_category_name IS NOT NULL
      AND TRIM(product_category_name) <> ''
),
category_sales AS (
    SELECT DISTINCT
        p.product_category_name,
        c.customer_state
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON c.customer_id = o.customer_id
    JOIN olist.order_items AS oi
        ON oi.order_id = o.order_id
    JOIN olist.products AS p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
      AND TRIM(p.product_category_name) <> ''
)
SELECT cat.product_category_name
FROM categories AS cat
WHERE NOT EXISTS (
    SELECT customer_state
    FROM target_states

    EXCEPT

    SELECT cs.customer_state
    FROM category_sales AS cs
    WHERE cs.product_category_name = cat.product_category_name
)
ORDER BY cat.product_category_name;


-- 4. Проверка эквивалентности трёх реализаций.
-- Сравниваем каждую пару результатов через EXCEPT в обе стороны.
-- Если все значения difference_count равны 0, множества совпадают.

WITH target_states(customer_state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),
categories AS (
    SELECT DISTINCT product_category_name
    FROM olist.products
    WHERE product_category_name IS NOT NULL
      AND TRIM(product_category_name) <> ''
),
category_sales AS (
    SELECT DISTINCT
        p.product_category_name,
        c.customer_state
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON c.customer_id = o.customer_id
    JOIN olist.order_items AS oi
        ON oi.order_id = o.order_id
    JOIN olist.products AS p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
      AND TRIM(p.product_category_name) <> ''
),
result_1 AS (
    SELECT cat.product_category_name
    FROM categories AS cat
    WHERE NOT EXISTS (
        SELECT 1
        FROM target_states AS ts
        WHERE NOT EXISTS (
            SELECT 1
            FROM category_sales AS cs
            WHERE cs.product_category_name = cat.product_category_name
              AND cs.customer_state = ts.customer_state
        )
    )
),
result_2 AS (
    SELECT cat.product_category_name
    FROM categories AS cat
    LEFT JOIN category_sales AS cs
        ON cs.product_category_name = cat.product_category_name
       AND cs.customer_state IN (
           SELECT customer_state
           FROM target_states
       )
    GROUP BY cat.product_category_name
    HAVING COUNT(DISTINCT cs.customer_state) = (
        SELECT COUNT(*)
        FROM target_states
    )
),
result_3 AS (
    SELECT cat.product_category_name
    FROM categories AS cat
    WHERE NOT EXISTS (
        SELECT customer_state
        FROM target_states
        EXCEPT
        SELECT cs.customer_state
        FROM category_sales AS cs
        WHERE cs.product_category_name = cat.product_category_name
    )
)
SELECT '1 минус 2' AS comparison, COUNT(*) AS difference_count
FROM (
    SELECT * FROM result_1
    EXCEPT
    SELECT * FROM result_2
) AS diff

UNION ALL

SELECT '2 минус 1', COUNT(*)
FROM (
    SELECT * FROM result_2
    EXCEPT
    SELECT * FROM result_1
) AS diff

UNION ALL

SELECT '1 минус 3', COUNT(*)
FROM (
    SELECT * FROM result_1
    EXCEPT
    SELECT * FROM result_3
) AS diff

UNION ALL

SELECT '3 минус 1', COUNT(*)
FROM (
    SELECT * FROM result_3
    EXCEPT
    SELECT * FROM result_1
) AS diff

UNION ALL

SELECT '2 минус 3', COUNT(*)
FROM (
    SELECT * FROM result_2
    EXCEPT
    SELECT * FROM result_3
) AS diff

UNION ALL

SELECT '3 минус 2', COUNT(*)
FROM (
    SELECT * FROM result_3
    EXCEPT
    SELECT * FROM result_2
) AS diff

ORDER BY comparison;


-- 5. Диагностика категории artes.
-- Считаем доставленные заказы с этой категорией в каждом нужном штате.
-- DISTINCT не позволяет считать один заказ несколько раз,
-- если в нём несколько товаров категории artes.

WITH target_states(customer_state) AS (
    VALUES ('PA'), ('AM'), ('RO')
)
SELECT
    p.product_category_name,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders_count
FROM olist.orders AS o
JOIN olist.customers AS c
    ON c.customer_id = o.customer_id
JOIN olist.order_items AS oi
    ON oi.order_id = o.order_id
JOIN olist.products AS p
    ON p.product_id = oi.product_id
JOIN target_states AS ts
    ON ts.customer_state = c.customer_state
WHERE o.order_status = 'delivered'
  AND p.product_category_name = 'artes'
GROUP BY
    p.product_category_name,
    c.customer_state
ORDER BY c.customer_state;


-- 6. Проверка трёх способов при пустом target_states.
-- Универсальное условие на пустом множестве истинно:
-- нет обязательного штата, в котором отсутствует продажа.
-- Поэтому каждый способ должен вернуть все категории
-- из categories, включая категории без доставленных заказов.

WITH target_states(customer_state) AS (
    SELECT NULL::text
    WHERE FALSE
),
categories AS (
    SELECT DISTINCT product_category_name
    FROM olist.products
    WHERE product_category_name IS NOT NULL
      AND TRIM(product_category_name) <> ''
),
category_sales AS (
    SELECT DISTINCT
        p.product_category_name,
        c.customer_state
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON c.customer_id = o.customer_id
    JOIN olist.order_items AS oi
        ON oi.order_id = o.order_id
    JOIN olist.products AS p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
      AND TRIM(p.product_category_name) <> ''
),
result_1 AS (
    SELECT cat.product_category_name
    FROM categories AS cat
    WHERE NOT EXISTS (
        SELECT 1
        FROM target_states AS ts
        WHERE NOT EXISTS (
            SELECT 1
            FROM category_sales AS cs
            WHERE cs.product_category_name = cat.product_category_name
              AND cs.customer_state = ts.customer_state
        )
    )
),
result_2 AS (
    SELECT cat.product_category_name
    FROM categories AS cat
    LEFT JOIN category_sales AS cs
        ON cs.product_category_name = cat.product_category_name
       AND cs.customer_state IN (
           SELECT customer_state
           FROM target_states
       )
    GROUP BY cat.product_category_name
    HAVING COUNT(DISTINCT cs.customer_state) = (
        SELECT COUNT(*)
        FROM target_states
    )
),
result_3 AS (
    SELECT cat.product_category_name
    FROM categories AS cat
    WHERE NOT EXISTS (
        SELECT customer_state
        FROM target_states
        EXCEPT
        SELECT cs.customer_state
        FROM category_sales AS cs
        WHERE cs.product_category_name = cat.product_category_name
    )
)
SELECT
    'Все категории с непустым названием' AS method,
    COUNT(*) AS categories_count
FROM categories

UNION ALL

SELECT 'Двойной NOT EXISTS', COUNT(*)
FROM result_1

UNION ALL

SELECT 'GROUP BY / HAVING', COUNT(*)
FROM result_2

UNION ALL

SELECT 'EXCEPT / NOT EXISTS', COUNT(*)
FROM result_3;

-- 7. Дополнительное задание.
-- Продавцы, продававшие товары покупателям
-- каждого из трёх штатов: PA, AM, RO.
-- Учитываем только доставленные заказы.

WITH target_states(customer_state) AS (
    VALUES ('PA'), ('AM'), ('RO')
),
seller_sales AS (
    SELECT DISTINCT
        oi.seller_id,
        c.customer_state
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON c.customer_id = o.customer_id
    JOIN olist.order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
)
SELECT s.seller_id
FROM olist.sellers AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM target_states AS ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM seller_sales AS ss
        WHERE ss.seller_id = s.seller_id
          AND ss.customer_state = ts.customer_state
    )
)
ORDER BY s.seller_id;