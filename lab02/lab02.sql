-- Автор: Тубольцева Лада
-- Группа: ИНБО-20-23
-- Практическая работа № 2
-- Вариант 1: A — штат SP, B — штат RJ

-- Запрос A: товары из доставленных заказов клиентов штата SP
SELECT oi.product_id
FROM olist.order_items AS oi
JOIN olist.orders AS o
    ON oi.order_id = o.order_id
JOIN olist.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_state = 'SP'
  AND o.order_status = 'delivered';

-- Количество строк и уникальных товаров в A
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT oi.product_id) AS unique_products
FROM olist.order_items AS oi
JOIN olist.orders AS o
    ON oi.order_id = o.order_id
JOIN olist.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_state = 'SP'
  AND o.order_status = 'delivered';

-- Запрос B: товары из доставленных заказов клиентов штата RJ
SELECT oi.product_id
FROM olist.order_items AS oi
JOIN olist.orders AS o
    ON oi.order_id = o.order_id
JOIN olist.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ'
  AND o.order_status = 'delivered';

-- Количество строк и уникальных товаров в B
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT oi.product_id) AS unique_products
FROM olist.order_items AS oi
JOIN olist.orders AS o
    ON oi.order_id = o.order_id
JOIN olist.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ'
  AND o.order_status = 'delivered';

-- Объединение A и B без повторов
SELECT oi.product_id
FROM olist.order_items AS oi
JOIN olist.orders AS o
    ON oi.order_id = o.order_id
JOIN olist.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_state = 'SP'
  AND o.order_status = 'delivered'

UNION

SELECT oi.product_id
FROM olist.order_items AS oi
JOIN olist.orders AS o
    ON oi.order_id = o.order_id
JOIN olist.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_state = 'RJ'
  AND o.order_status = 'delivered';


-- Количество товаров в объединении A и B
SELECT COUNT(*) AS union_count
FROM (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'SP'
      AND o.order_status = 'delivered'
    UNION
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ'
      AND o.order_status = 'delivered'
) AS combined;

-- Количество строк объединения A и B с повторами
SELECT COUNT(*) AS union_all_count
FROM (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'SP'
      AND o.order_status = 'delivered'
    UNION ALL
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ'
      AND o.order_status = 'delivered'
) AS combined;


-- UNION: 22211 строк без повторов.
-- UNION ALL: 60591 строк с повторами.
-- Разница возникает из-за повторов внутри A, внутри B
-- и товаров, встречающихся в обоих штатах.

-- Количество общих товаров A и B
SELECT COUNT(*) AS intersect_count
FROM (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'SP'
      AND o.order_status = 'delivered'
    INTERSECT
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ'
      AND o.order_status = 'delivered'
) AS common_products;

-- Количество товаров в A − B
SELECT COUNT(*) AS a_minus_b_count
FROM (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'SP'
      AND o.order_status = 'delivered'
    EXCEPT
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ'
      AND o.order_status = 'delivered'
) AS difference_products;

-- Количество товаров в B − A
SELECT COUNT(*) AS b_minus_a_count
FROM (
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'RJ'
      AND o.order_status = 'delivered'
    EXCEPT
    SELECT oi.product_id
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE c.customer_state = 'SP'
      AND o.order_status = 'delivered'
) AS difference_products;


-- Проверка коммутативности объединения
WITH base AS (
    SELECT oi.product_id, c.customer_state
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
a AS (
    SELECT product_id FROM base WHERE customer_state = 'SP'
),
b AS (
    SELECT product_id FROM base WHERE customer_state = 'RJ'
),
ab AS (
    SELECT product_id FROM a
    UNION
    SELECT product_id FROM b
),
ba AS (
    SELECT product_id FROM b
    UNION
    SELECT product_id FROM a
)
SELECT COUNT(*) AS differences
FROM (
    (SELECT product_id FROM ab EXCEPT SELECT product_id FROM ba)
    UNION ALL
    (SELECT product_id FROM ba EXCEPT SELECT product_id FROM ab)
) AS comparison;


-- Проверка коммутативности пересечения
WITH base AS (
    SELECT oi.product_id, c.customer_state
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON oi.order_id = o.order_id
    JOIN olist.customers AS c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
a AS (
    SELECT product_id FROM base WHERE customer_state = 'SP'
),
b AS (
    SELECT product_id FROM base WHERE customer_state = 'RJ'
),
ab AS (
    SELECT product_id FROM a
    INTERSECT
    SELECT product_id FROM b
),
ba AS (
    SELECT product_id FROM b
    INTERSECT
    SELECT product_id FROM a
)
SELECT COUNT(*) AS differences
FROM (
    (SELECT product_id FROM ab EXCEPT SELECT product_id FROM ba)
    UNION ALL
    (SELECT product_id FROM ba EXCEPT SELECT product_id FROM ab)
) AS comparison;

-- Пересечение через EXISTS
SELECT DISTINCT oi.product_id
FROM olist.order_items AS oi
JOIN olist.orders AS o ON oi.order_id = o.order_id
JOIN olist.customers AS c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'SP'
  AND o.order_status = 'delivered'
  AND EXISTS (
      SELECT 1
      FROM olist.order_items AS oi_b
      JOIN olist.orders AS o_b ON oi_b.order_id = o_b.order_id
      JOIN olist.customers AS c_b ON o_b.customer_id = c_b.customer_id
      WHERE c_b.customer_state = 'RJ'
        AND o_b.order_status = 'delivered'
        AND oi_b.product_id = oi.product_id
  );


-- Пересечение через EXISTS без DISTINCT: проверка повторов
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT oi.product_id) AS unique_products
FROM olist.order_items AS oi
JOIN olist.orders AS o ON oi.order_id = o.order_id
JOIN olist.customers AS c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'SP'
  AND o.order_status = 'delivered'
  AND EXISTS (
      SELECT 1
      FROM olist.order_items AS oi_b
      JOIN olist.orders AS o_b ON oi_b.order_id = o_b.order_id
      JOIN olist.customers AS c_b ON o_b.customer_id = c_b.customer_id
      WHERE c_b.customer_state = 'RJ'
        AND o_b.order_status = 'delivered'
        AND oi_b.product_id = oi.product_id
  );


-- ВЫВОДЫ
-- Множество содержит только уникальные элементы.
-- Мультимножество допускает повторяющиеся элементы.
--
-- UNION, INTERSECT и EXCEPT без ALL удаляют дубликаты:
-- их результаты являются множествами.
-- SELECT DISTINCT также удаляет дубликаты.
--
-- Обычный SELECT и UNION ALL сохраняют повторы
-- и могут возвращать мультимножества.
-- INTERSECT ALL и EXCEPT ALL тоже могут сохранять повторы.
-- EXISTS проверяет наличие совпадения, но сам не удаляет
-- дубликаты из результата внешнего запроса.
--
-- UNION: 22211 товаров; UNION ALL: 60591 строка.
-- EXISTS без DISTINCT: 22731 строка, 4170 разных товаров.
--
-- Объединение и пересечение коммутативны:
-- A UNION B = B UNION A;
-- A INTERSECT B = B INTERSECT A.
-- Обе проверки дали 0 различий.
--
-- Разность некоммутативна:
-- A EXCEPT B содержит 14539 товаров,
-- B EXCEPT A содержит 3502 товара.
--
-- Без ORDER BY порядок строк не гарантирован.