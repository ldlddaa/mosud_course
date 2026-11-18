# Практическая работа № 1. Развёртывание PostgreSQL и загрузка Olist

Автор: Тубольцева Лада. Группа: ИНБО-20-23.

- PostgreSQL 17.5, установлен и запущен локально на macOS.
- Подключение: `localhost:5432`, база `olist`, схемы `olist` и `lab`.
- Импорт: восемь CSV загружены через DBeaver, отзывы — через команду `\copy` в psql.
- Строки: `customers` — 99 441, `orders` — 99 441, `order_items` — 112 650.
- Строки: `order_payments` — 103 886, `order_reviews` — 99 224, `products` — 32 951.
- Строки: `sellers` — 3 095, `geolocation` — 1 000 163, `product_category_name_translation` — 71.
- Проверки `check.sql`: в ключевых полях 0 NULL, все 6 проверок внешних ссылок дали 0.

- Подтверждено в базе: 8 первичных и 6 внешних ключей.
- Выполнен `ANALYZE` для всех 9 таблиц схемы `olist`.
