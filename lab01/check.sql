-- Автор: Тубольцева Лада
-- Группа: ИНБО-20-23
-- Практическая работа № 1; без варианта
-- 1. Считаем строки во всех девяти таблицах.
SELECT 'customers' AS table_name, count(*) AS row_count FROM olist.customers
UNION ALL SELECT 'geolocation', count(*) FROM olist.geolocation
UNION ALL SELECT 'orders', count(*) FROM olist.orders
UNION ALL SELECT 'order_items', count(*) FROM olist.order_items
UNION ALL SELECT 'order_payments', count(*) FROM olist.order_payments
UNION ALL SELECT 'order_reviews', count(*) FROM olist.order_reviews
UNION ALL SELECT 'products', count(*) FROM olist.products
UNION ALL SELECT 'sellers', count(*) FROM olist.sellers
UNION ALL SELECT 'product_category_name_translation', count(*)
FROM olist.product_category_name_translation
ORDER BY table_name;

-- 2. Считаем строки с NULL хотя бы в одном ключевом поле.
SELECT 'customers' AS table_name, count(*) AS null_key_rows
FROM olist.customers WHERE customer_id IS NULL
UNION ALL SELECT 'orders', count(*)
FROM olist.orders WHERE order_id IS NULL OR customer_id IS NULL
UNION ALL SELECT 'order_items', count(*)
FROM olist.order_items
WHERE order_id IS NULL OR order_item_id IS NULL
   OR product_id IS NULL OR seller_id IS NULL
UNION ALL SELECT 'order_payments', count(*)
FROM olist.order_payments WHERE order_id IS NULL OR payment_sequential IS NULL
UNION ALL SELECT 'order_reviews', count(*)
FROM olist.order_reviews WHERE review_id IS NULL OR order_id IS NULL
UNION ALL SELECT 'products', count(*)
FROM olist.products WHERE product_id IS NULL
UNION ALL SELECT 'sellers', count(*)
FROM olist.sellers WHERE seller_id IS NULL
UNION ALL SELECT 'product_category_name_translation', count(*)
FROM olist.product_category_name_translation WHERE product_category_name IS NULL
ORDER BY table_name;

-- 3. Ищем ссылки, для которых нет связанной записи.
SELECT 'orders → customers' AS relation, count(*) AS orphan_rows
FROM olist.orders o
LEFT JOIN olist.customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
UNION ALL SELECT 'order_items → orders', count(*)
FROM olist.order_items i
LEFT JOIN olist.orders o ON o.order_id = i.order_id
WHERE o.order_id IS NULL
UNION ALL SELECT 'order_items → products', count(*)
FROM olist.order_items i
LEFT JOIN olist.products p ON p.product_id = i.product_id
WHERE p.product_id IS NULL
UNION ALL SELECT 'order_items → sellers', count(*)
FROM olist.order_items i
LEFT JOIN olist.sellers s ON s.seller_id = i.seller_id
WHERE s.seller_id IS NULL
UNION ALL SELECT 'order_payments → orders', count(*)
FROM olist.order_payments p
LEFT JOIN olist.orders o ON o.order_id = p.order_id
WHERE o.order_id IS NULL
UNION ALL SELECT 'order_reviews → orders', count(*)
FROM olist.order_reviews r
LEFT JOIN olist.orders o ON o.order_id = r.order_id
WHERE o.order_id IS NULL;

-- 4. Проверяем количество первичных и внешних ключей (ожидается p = 8, f = 6).
SELECT contype AS constraint_type, COUNT(*) AS constraint_count
FROM pg_constraint
WHERE connamespace = 'olist'::regnamespace
  AND contype IN ('p', 'f')
GROUP BY contype;

-- 5. Обновляем статистику после загрузки данных.
ANALYZE olist.customers;
ANALYZE olist.geolocation;
ANALYZE olist.orders;
ANALYZE olist.order_items;
ANALYZE olist.order_payments;
ANALYZE olist.order_reviews;
ANALYZE olist.products;
ANALYZE olist.sellers;
ANALYZE olist.product_category_name_translation;
