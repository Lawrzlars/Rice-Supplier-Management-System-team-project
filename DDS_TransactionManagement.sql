/*
TRANSACTION MANAGEMENT
*/

/*
FULL TRANSACTION (COMMIT CASE)
*/

START TRANSACTION;

-- RESET EXPECTATION (for clean demo behavior)
UPDATE loyalty_card SET points_balance = 0, tier_level = 'BRONZE';

-- SALE 1
INSERT INTO sales (customer_id, employee_id, sale_date, sale_status)
VALUES (1, 1001, NOW(), 'PAID');

SET @sale1 = LAST_INSERT_ID();

INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, subtotal)
VALUES (@sale1, 1, 50, 1250.00, 62500.00); 

INSERT INTO payments (sale_id, payment_method, amount_paid, reference_number, payment_status)
VALUES (@sale1, 'CASH', 62500.00, 'TXN-GOLD-1', 'PAID');

-------------------------------------------------
-- SALE 2
INSERT INTO sales (customer_id, employee_id, sale_date, sale_status)
VALUES (2, 1002, NOW(), 'PAID');

SET @sale2 = LAST_INSERT_ID();

INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, subtotal)
VALUES (@sale2, 2, 20, 1180.00, 23600.00);

INSERT INTO payments (sale_id, payment_method, amount_paid, reference_number, payment_status)
VALUES (@sale2, 'CASH', 23600.00, 'TXN-SILVER-1', 'PAID');


-- SALE 3
INSERT INTO sales (customer_id, employee_id, sale_date, sale_status)
VALUES (3, 1003, NOW(), 'PAID');

SET @sale3 = LAST_INSERT_ID();

INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, subtotal)
VALUES (@sale3, 3, 3, 1370.00, 4110.00);

INSERT INTO payments (sale_id, payment_method, amount_paid, reference_number, payment_status)
VALUES (@sale3, 'CASH', 4110.00, 'TXN-BRONZE-1', 'PAID');


-- SALE 4
INSERT INTO sales (customer_id, employee_id, sale_date, sale_status)
VALUES (4, 1004, NOW(), 'PENDING');

SET @sale4 = LAST_INSERT_ID();

INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, subtotal)
VALUES (@sale4, 4, 10, 1100.00, 11000.00);

INSERT INTO payments (sale_id, payment_method, amount_paid, reference_number, payment_status)
VALUES (@sale4, 'COD', 11000.00, 'TXN-DEBT-1', 'PENDING');

INSERT INTO debt_tracker (customer_id, sale_id, amount_owed, amount_paid, due_date, debt_status)
VALUES (4, @sale4, 11000.00, 2000.00, '2026-12-31', 'PENDING');


-- SALE 5
INSERT INTO sales (customer_id, employee_id, sale_date, sale_status)
VALUES (5, 1005, NOW(), 'PENDING');

SET @sale5 = LAST_INSERT_ID();

INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, subtotal)
VALUES (@sale5, 5, 5, 1650.00, 8250.00);

INSERT INTO payments (sale_id, payment_method, amount_paid, reference_number, payment_status)
VALUES (@sale5, 'GCASH', 8250.00, 'TXN-FAIL-1', 'FAILED');

COMMIT;

/*--------------------------------------------------------------------------*/


/*
FAILURE + ROLLBACK DEMO
*/

START TRANSACTION;

INSERT INTO sales (customer_id, employee_id, sale_date, sale_status)
VALUES (2, 1002, NOW(), 'PAID');

SET @sale_id = LAST_INSERT_ID();

-- This may FAIL if stock is insufficient
INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, subtotal)
VALUES (@sale_id, 1, 9999, 1250.00, 12487500.00);

-- If error occurs → rollback everything
ROLLBACK;


/*--------------------------------------------------------------------------*/


/*
CHECK TRANSACTION RESULT
*/

SELECT * FROM sales ORDER BY sale_id DESC;
SELECT product_id, quantity_on_hand FROM inventory;
SELECT * FROM payments ORDER BY payment_id DESC;
SELECT customer_id, points_balance, tier_level
FROM loyalty_card;

-- FOR SECURITY ROLES
SELECT User, Host
FROM mysql.user;
SHOW GRANTS FOR 'admin_user'@'localhost';
SHOW GRANTS FOR 'staff_user'@'localhost';

SHOW TRIGGERS;
ROLLBACK;