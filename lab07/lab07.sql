-- Практическая работа №7
-- Тема: NULL, трёхзначная логика и качество данных
-- Выполнила: Тубольцева Лада
-- Группа: ИНБО-20-23

-- 1. Количество NULL в необязательных столбцах orders.
-- COUNT(*) считает все строки.
-- COUNT(столбец) считает строки с известным значением.
-- Разница между ними — количество NULL.

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) - COUNT(order_status) AS null_status,
    COUNT(*) - COUNT(order_purchase_timestamp) AS null_purchase,
    COUNT(*) - COUNT(order_approved_at) AS null_approved,
    COUNT(*) - COUNT(order_delivered_carrier_date) AS null_carrier,
    COUNT(*) - COUNT(order_delivered_customer_date) AS null_delivered,
    COUNT(*) - COUNT(order_estimated_delivery_date) AS null_estimated
FROM olist.orders;

-- 1. Количество NULL в необязательных столбцах products.

SELECT
    COUNT(*) AS total_products,
    COUNT(*) - COUNT(product_category_name) AS null_category,
    COUNT(*) - COUNT(product_name_lenght) AS null_name_length,
    COUNT(*) - COUNT(product_description_lenght) AS null_description_length,
    COUNT(*) - COUNT(product_photos_qty) AS null_photos,
    COUNT(*) - COUNT(product_weight_g) AS null_weight,
    COUNT(*) - COUNT(product_length_cm) AS null_length,
    COUNT(*) - COUNT(product_height_cm) AS null_height,
    COUNT(*) - COUNT(product_width_cm) AS null_width
FROM olist.products;

-- Дополнительная проверка: NULL и пустые категории товаров.

SELECT
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS null_category,
    COUNT(*) FILTER (
        WHERE product_category_name IS NOT NULL
          AND BTRIM(product_category_name) = ''
    ) AS empty_category,
    COUNT(*) FILTER (
        WHERE BTRIM(product_category_name) <> ''
    ) AS filled_category
FROM olist.products;

-- 1. Количество NULL в необязательных столбцах order_reviews.
-- Дополнительно проверяем пустые строки в заголовке и тексте.

SELECT
    COUNT(*) AS total_reviews,
    COUNT(*) - COUNT(review_score) AS null_score,
    COUNT(*) - COUNT(review_comment_title) AS null_title,
    COUNT(*) - COUNT(review_comment_message) AS null_message,
    COUNT(*) - COUNT(review_creation_date) AS null_creation_date,
    COUNT(*) - COUNT(review_answer_timestamp) AS null_answer_timestamp,
    COUNT(*) FILTER (
        WHERE BTRIM(review_comment_title) = ''
    ) AS empty_title,
    COUNT(*) FILTER (
        WHERE BTRIM(review_comment_message) = ''
    ) AS empty_message
FROM olist.order_reviews;

-- 2. Сравнение COUNT(*) и COUNT(order_delivered_customer_date).
-- COUNT(*) учитывает все заказы.
-- COUNT(столбец) учитывает только строки, где столбец не NULL.

SELECT
    COUNT(*) AS all_orders,
    COUNT(order_delivered_customer_date) AS orders_with_delivery_date,
    COUNT(*) - COUNT(order_delivered_customer_date) AS orders_without_delivery_date
FROM olist.orders;

-- Разница — заказы, у которых фактическая дата доставки не указана.


-- 3. Сравнение с NULL: неправильный и правильный способы.

SELECT
    'Неправильно: = NULL' AS check_name,
    COUNT(*) AS orders_count
FROM olist.orders
WHERE order_delivered_customer_date = NULL

UNION ALL

SELECT
    'Неправильно: <> NULL',
    COUNT(*)
FROM olist.orders
WHERE order_delivered_customer_date <> NULL

UNION ALL

SELECT
    'Правильно: IS NULL',
    COUNT(*)
FROM olist.orders
WHERE order_delivered_customer_date IS NULL

UNION ALL

SELECT
    'Правильно: IS NOT NULL',
    COUNT(*)
FROM olist.orders
WHERE order_delivered_customer_date IS NOT NULL;

-- Обычные сравнения = NULL и <> NULL дают UNKNOWN.
-- WHERE пропускает только строки, для которых условие TRUE.
-- Поэтому для проверки пропусков нужны IS NULL / IS NOT NULL.

-- 4. Сравнение обычного <> и IS DISTINCT FROM.
-- IS DISTINCT FROM всегда возвращает TRUE или FALSE,
-- даже если одно или оба значения равны NULL.

SELECT
    example_no,
    value_1,
    value_2,
    value_1 <> value_2 AS ordinary_comparison,
    value_1 IS DISTINCT FROM value_2 AS null_safe_comparison
FROM (
    VALUES
        (1, 'delivered', 'delivered'),
        (2, 'delivered', 'canceled'),
        (3, 'delivered', NULL),
        (4, NULL, NULL)
) AS examples(example_no, value_1, value_2)
ORDER BY example_no;

-- Одинаковые значения: FALSE.
-- Разные значения: TRUE.
-- Значение и NULL: TRUE.
-- Два NULL: FALSE.

-- 5. Сравнение NOT IN и NOT EXISTS при наличии NULL.

CREATE TEMP TABLE temp_ids (
    id text
);

-- Добавляем один существующий order_id и один NULL.
INSERT INTO temp_ids (id)
VALUES
    ((SELECT MIN(order_id) FROM olist.orders)),
    (NULL);

-- Считаем заказы, отсутствующие во временной таблице.
SELECT
    'NOT IN' AS method,
    COUNT(*) AS orders_count
FROM olist.orders
WHERE order_id NOT IN (
    SELECT id
    FROM temp_ids
)

UNION ALL

SELECT
    'NOT EXISTS',
    COUNT(*)
FROM olist.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM temp_ids t
    WHERE t.id = o.order_id
);

-- NULL в списке мешает NOT IN вернуть TRUE.
-- NOT EXISTS проверяет отсутствие совпадения:
-- NULL не совпадает ни с одним order_id.


-- 6. Влияние расположения фильтра на результат LEFT JOIN.

-- Фильтр в ON: сохраняем все заказы,
-- присоединяем только отзывы с оценкой не ниже 4.
SELECT
    'Фильтр в ON' AS filter_position,
    COUNT(*) AS result_rows,
    COUNT(DISTINCT o.order_id) AS unique_orders
FROM olist.orders o
LEFT JOIN olist.order_reviews r
    ON r.order_id = o.order_id
   AND r.review_score >= 4

UNION ALL

-- Фильтр в WHERE: оставляем только строки,
-- в которых есть отзыв с оценкой не ниже 4.
SELECT
    'Фильтр в WHERE',
    COUNT(*),
    COUNT(DISTINCT o.order_id)
FROM olist.orders o
LEFT JOIN olist.order_reviews r
    ON r.order_id = o.order_id
WHERE r.review_score >= 4;

-- В ON условие определяет, какие отзывы присоединятся.
-- Заказы без подходящего отзыва сохраняются.
-- В WHERE условие отбирает строки после соединения.
-- Строки без подходящего отзыва отбрасываются:
-- NULL >= 4 даёт UNKNOWN.

-- 7. COALESCE: подстановка текста вместо отсутствующего комментария.
-- Учитываем и NULL, и пустые строки.

SELECT
    review_id,
    review_comment_message AS original_comment,
    COALESCE(
        NULLIF(BTRIM(review_comment_message), ''),
        'Комментарий отсутствует'
    ) AS displayed_comment
FROM olist.order_reviews
ORDER BY review_id, order_id
LIMIT 10;

-- BTRIM убирает пробелы по краям.
-- NULLIF превращает пустую строку в NULL.
-- COALESCE подставляет надпись, если получилось NULL.


-- NULLIF: защита от деления на ноль.

SELECT
    numerator,
    denominator,
    numerator::numeric / NULLIF(denominator, 0) AS division_result
FROM (
    VALUES
        (10, 2),
        (10, 0)
) AS examples(numerator, denominator);

-- Если знаменатель равен 0, NULLIF заменяет его на NULL.
-- Результат деления будет NULL, ошибка не возникнет.

-- 8. Мини-профиль качества данных.
-- Для текстовых полей учитываем NULL, пустые строки и пробелы.

SELECT
    'Заказы без фактической даты доставки' AS indicator,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_records,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date IS NULL
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS missing_percent
FROM olist.orders

UNION ALL

SELECT
    'Товары без категории',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(product_category_name), '') IS NULL
    ),
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE NULLIF(BTRIM(product_category_name), '') IS NULL
        ) / NULLIF(COUNT(*), 0),
        2
    )
FROM olist.products

UNION ALL

SELECT
    'Отзывы без текста',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(review_comment_message), '') IS NULL
    ),
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE NULLIF(BTRIM(review_comment_message), '') IS NULL
        ) / NULLIF(COUNT(*), 0),
        2
    )
FROM olist.order_reviews;


-- 9. Естественные пропуски и проблемы качества данных.

-- Естественный NULL: order_reviews.review_comment_message.
-- Покупатель может поставить оценку, не написав комментарий.
-- Поэтому отсутствие текста само по себе не означает ошибку.
-- Обнаружено 58 247 NULL и 9 пустых строк.

-- Возможная проблема качества: products.product_weight_g.
-- У 2 товаров вес равен NULL.
-- Для физического товара вес нужен при расчёте доставки,
-- поэтому такой пропуск скорее указывает на неполные данные.

-- Дополнительный вывод: отсутствие фактической даты доставки
-- нужно оценивать с учётом статуса заказа.
-- Для отменённого или ещё не доставленного заказа это естественно.
-- Для заказа со статусом delivered такой пропуск подозрителен.

-- В текстовых полях отсутствие значения может быть представлено
-- как NULL или пустая строка. Поэтому профиль качества учитывает оба случая.

DROP TABLE IF EXISTS pg_temp.temp_ids;

