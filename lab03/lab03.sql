-- Тубольцева Лада
-- Группа: ИНБО-20-23
-- Практическая работа № 3
-- Вариант: 2

-- Отбираем позиции заказов с ценой от 100 до 500 включительно
-- и стоимостью доставки меньше 50.
-- Выводим идентификаторы заказа, товара, продавца и цену.

SELECT
    order_id,
    product_id,
    seller_id,
    price
FROM olist.order_items
WHERE price BETWEEN 100 AND 500
  AND freight_value < 50;

-- Разбиваем отбор на два последовательных шага:
-- сначала по цене, затем по стоимости доставки.

SELECT
    order_id,
    product_id,
    seller_id,
    price
FROM (
    SELECT *
    FROM olist.order_items
    WHERE price BETWEEN 100 AND 500
) AS filtered_by_price
WHERE freight_value < 50;

-- Проверяем эквивалентность двух способов отбора.
WITH original AS (
    SELECT order_id, product_id, seller_id, price
    FROM olist.order_items
    WHERE price BETWEEN 100 AND 500
      AND freight_value < 50
),
sequential AS (
    SELECT order_id, product_id, seller_id, price
    FROM (
        SELECT *
        FROM olist.order_items
        WHERE price BETWEEN 100 AND 500
    ) AS filtered_by_price
    WHERE freight_value < 50
)
SELECT
    (
        SELECT COUNT(*)
        FROM (
            SELECT * FROM original
            EXCEPT ALL
            SELECT * FROM sequential
        ) AS diff
    ) AS only_in_original,
    (
        SELECT COUNT(*)
        FROM (
            SELECT * FROM sequential
            EXCEPT ALL
            SELECT * FROM original
        ) AS diff
    ) AS only_in_sequential;


-- Исключаем ненужные столбцы во внутреннем запросе.

SELECT
    order_id,
    product_id,
    seller_id,
    price
FROM (
    SELECT
        order_id,
        product_id,
        seller_id,
        price,
        freight_value
    FROM olist.order_items
    WHERE price BETWEEN 100 AND 500
) AS filtered_by_price
WHERE freight_value < 50;


-- Сравниваем количество всех строк и уникальных строк.
WITH result AS (
    SELECT order_id, product_id, seller_id, price
    FROM olist.order_items
    WHERE price BETWEEN 100 AND 500
      AND freight_value < 50
),
unique_result AS (
    SELECT DISTINCT *
    FROM result
)
SELECT
    (SELECT COUNT(*) FROM result) AS total_rows,
    (SELECT COUNT(*) FROM unique_result) AS unique_rows,
    (SELECT COUNT(*) FROM result)
        - (SELECT COUNT(*) FROM unique_result) AS duplicate_rows;


-- Проекция без дубликатов, соответствующая реляционной алгебре.
SELECT DISTINCT
    order_id,
    product_id,
    seller_id,
    price
FROM olist.order_items
WHERE price BETWEEN 100 AND 500
  AND freight_value < 50;