/*
SCHEMA
*/
CREATE DATABASE rice_supplier;
USE rice_supplier;

/*CUSTOMER SECTION*/
-- This table stores customer information used in the system.
-- It keeps track of customer details, contact information,
-- and customer type for transactions and monitoring.

CREATE TABLE customers (
-- Unique ID for each customer
    customer_id INT PRIMARY KEY AUTO_INCREMENT, 
    full_name VARCHAR(100) NOT NULL,
-- Limits customer type into two valid choices only
    customer_type ENUM('RESELLER', 'WALK-IN') NOT NULL, 
    contact_number VARCHAR(15) NOT NULL,
    address VARCHAR(255),
    email VARCHAR(100),
-- Automatically records registration date and time
    registered_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- This table stores loyalty card information including reward points, tier level, issue and expiry dates, and card status. It functions as the customer rewards system where one customer can only own one loyalty card and points cannot be negative.
CREATE TABLE loyalty_card (
    loyalty_card_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT UNIQUE NOT NULL,
    points_balance DECIMAL(10,2) DEFAULT 0,
    tier_level VARCHAR(20) NOT NULL DEFAULT 'BRONZE',
    issued_at DATE NOT NULL,
    expiry_date DATE NOT NULL,
    card_status VARCHAR(10) NOT NULL,
    -- Links loyalty cards to customers and automatically updates or removes related records
	CONSTRAINT fk_loyalty_customer
		FOREIGN KEY (customer_id)
		REFERENCES customers(customer_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
    
	CONSTRAINT chk_points_balance
		CHECK (points_balance >= 0),
    -- Restricts tier values into valid membership levels only
	CONSTRAINT chk_tier_level
		CHECK (tier_level IN ('BRONZE', 'SILVER', 'GOLD')),
    
	CONSTRAINT chk_card_status
		CHECK (card_status IN ('ACTIVE', 'EXPIRED')),
    -- Ensures expiry date is always later than issue date
	CONSTRAINT chk_expiry_date
		CHECK (expiry_date > issued_at)
);

/*EMPLOYEE SECTION*/
CREATE TABLE employee (
employee_id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL,
contact_number VARCHAR(15) NOT NULL,
email VARCHAR(50) NOT NULL UNIQUE,
position_role VARCHAR(100) NOT NULL,
hire_date DATE NOT NULL,
employee_status VARCHAR(10) NOT NULL,

-- Ensures only active or inactive employee records 
CONSTRAINT chk_emp_status
	CHECK (employee_status IN ('ACTIVE', 'INACTIVE'))
)AUTO_INCREMENT = 1001;

/*Sales and Inventory section*/
-- Ensures only valid product statuses are stored 
CREATE TABLE rice_products(
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL UNIQUE,
    variety VARCHAR(50),
    unit VARCHAR(50) NOT NULL,
	price_per_unit DECIMAL(10,2) NOT NULL,
    product_status VARCHAR(20) NOT NULL,
    
    CHECK (product_status IN ('AVAILABLE', 'NOT AVAILABLE'))
);
CREATE TABLE inventory(
inventory_id INT PRIMARY KEY AUTO_INCREMENT,
product_id INT NOT NULL UNIQUE,
quantity_on_hand DECIMAL(10,2) NOT NULL,
reorder_level DECIMAL(10,2) NOT NULL,
last_updated DATETIME NOT NULL,
warehouse_location VARCHAR(100),

-- Links inventory records to rice products
CONSTRAINT fk_inventory_product
FOREIGN KEY (product_id)
REFERENCES rice_products(product_id)
); 
CREATE TABLE sales (
sale_id INT PRIMARY KEY AUTO_INCREMENT,
customer_id INT NOT NULL,
employee_id INT NOT NULL,
sale_date DATETIME NOT NULL ,
sale_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',

-- Restricts sale status to valid transaction states 
CHECK (sale_status IN ('PAID', 'PENDING', 'CANCELLED')),

CONSTRAINT fk_sales_customer
	FOREIGN KEY (customer_id)
	REFERENCES customers(customer_id),

CONSTRAINT fk_sales_employee
	FOREIGN KEY (employee_id)
	REFERENCES employee(employee_id)

);
CREATE TABLE sale_items(
item_id INT PRIMARY KEY AUTO_INCREMENT,
sale_id INT NOT NULL,
product_id INT NOT NULL,
quantity INT NOT NULL CHECK (quantity > 0),
unit_price DECIMAL(10,2) NOT NULL,
subtotal DECIMAL(10,2) NOT NULL,

-- Validates subtotal calculation 
CONSTRAINT chk_saleitems_subtotal
	CHECK (subtotal = quantity * unit_price),

CONSTRAINT fk_saleitems_sale
	FOREIGN KEY (sale_id)
	REFERENCES sales(sale_id),

CONSTRAINT fk_saleitems_product
	FOREIGN KEY (product_id)
	REFERENCES rice_products(product_id)
);
-- This table stores supplier information such as supplier name, contact person, contact number, email, and address to help manage supplier records and communication details.
CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    contact_number VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL,
    -- Ensures supplier email follows a valid email format
	CONSTRAINT chk_supplier_email
		CHECK (email LIKE '%@%.%')
);
CREATE TABLE supplier_orders(
supplier_order_id INT PRIMARY KEY AUTO_INCREMENT,
supplier_id INT NOT NULL,
order_date DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
expected_delivery DATETIME,
actual_delivery DATETIME,
order_status VARCHAR(20) NOT NULL,
payment_status VARCHAR(20),

-- Delivery date must be later than order date
CHECK (order_date < expected_delivery),

-- Restricts order status values
CHECK (order_status IN('RECEIVED', 'PENDING', 'CANCELLED')),

-- Restricts payment status values
CHECK (payment_status IN('PAID', 'UNPAID', 'PARTIAL')),

CONSTRAINT fk_supplier
FOREIGN KEY (supplier_id)
REFERENCES suppliers(supplier_id)
); 
CREATE TABLE supplier_order_items(
supplier_order_item_id INT PRIMARY KEY AUTO_INCREMENT,
supplier_order_id INT NOT NULL,
quantity DECIMAL(10,2) NOT NULL,
cost_per_unit DECIMAL(10,2) NOT NULL,
subtotal DECIMAL(10,2) NOT NULL,
product_id INT NOT NULL,

-- Prevents ordering zero or negative quantities
CHECK (quantity > 0),

-- Automatically validates subtotal accuracy
CONSTRAINT chk_supplier_order_item_subtotal
CHECK (subtotal = quantity * cost_per_unit),

CONSTRAINT fk_supplier_order
FOREIGN KEY (supplier_order_id)
REFERENCES supplier_orders(supplier_order_id),

CONSTRAINT fk_soi_product
FOREIGN KEY (product_id)
REFERENCES rice_products(product_id)
); 
-- This table tracks customer debts, payment balances, due dates, and debt status to monitor unpaid transactions and payment progress connected to sales records.
CREATE TABLE debt_tracker (
    debt_id INT PRIMARY KEY AUTO_INCREMENT,
	customer_id INT NOT NULL,
    sale_id INT NOT NULL,
    amount_owed DECIMAL(10,2) NOT NULL,
	amount_paid DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    debt_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    -- Connects debt records to existing customers only
    CONSTRAINT fk_debt_customer
		FOREIGN KEY (customer_id)
		REFERENCES customers(customer_id),
    -- Automatically updates or deletes related debt records where sales data changes
    CONSTRAINT fk_debt_sale_id
		FOREIGN KEY (sale_id)
		REFERENCES sales(sale_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
   -- Prevents negative debt amounts
    CONSTRAINT chk_amount_owed
		CHECK (amount_owed >= 0),
    -- Restricts debt status into valid payment states only
    CONSTRAINT chk_debt_status
		CHECK (debt_status IN ('PENDING', 'PAID', 'OVERDUE'))
);

CREATE TABLE inventory_log(
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    employee_id INT NOT NULL,
    supplier_order_id INT,
    sale_id INT,

    transaction_type VARCHAR(10) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,

    imported_at DATETIME DEFAULT NULL,
    exported_at DATETIME DEFAULT NULL,

    CONSTRAINT fk_log_product
        FOREIGN KEY (product_id)
        REFERENCES rice_products(product_id),

    CONSTRAINT fk_employee
        FOREIGN KEY (employee_id)
        REFERENCES employee(employee_id),

    CONSTRAINT fk_supplier_order_id
        FOREIGN KEY (supplier_order_id)
        REFERENCES supplier_orders(supplier_order_id),

    CONSTRAINT fk_sale_id
        FOREIGN KEY (sale_id)
        REFERENCES sales(sale_id),

    CONSTRAINT chk_transaction_type
        CHECK (transaction_type IN ('IMPORT', 'EXPORT')),

    CONSTRAINT chk_import_export_logic
        CHECK (
            (transaction_type = 'IMPORT' AND supplier_order_id IS NOT NULL AND sale_id IS NULL)
            OR
            (transaction_type = 'EXPORT' AND sale_id IS NOT NULL AND supplier_order_id IS NULL)
        ),
        
	CHECK (
		(transaction_type = 'IMPORT' AND imported_at IS NOT NULL AND exported_at IS NULL)
		OR
		(transaction_type = 'EXPORT' AND exported_at IS NOT NULL AND imported_at IS NULL)
	)
);
CREATE TABLE payments (
payment_id INT PRIMARY KEY AUTO_INCREMENT,
sale_id INT NOT NULL,
payment_method VARCHAR(20) NOT NULL,
amount_paid DECIMAL(10,2) NOT NULL,
reference_number VARCHAR(50) NOT NULL UNIQUE ,
paid_at DATETIME DEFAULT CURRENT_TIMESTAMP,
payment_status VARCHAR(20) NOT NULL,
points_awarded INT NOT NULL DEFAULT 0,

-- Restricts payment processing status 
CHECK (payment_status IN('PAID', 'PENDING', 'FAILED')),
-- Restricts accepted payment methods 
CHECK (payment_method IN('GCASH', 'CASH', 'COD')),

CONSTRAINT fk_payments_sale
	FOREIGN KEY (sale_id)
	REFERENCES sales(sale_id)
);

COMMIT;

/*-------------------------------------------------------------------------------*/

-- TRIGGERS

-- INVENTORY MANAGEMENT BASED ON SALES
DELIMITER $$

CREATE TRIGGER trg_check_inventory_before_sale
BEFORE INSERT ON sale_items
FOR EACH ROW
BEGIN
DECLARE current_stock DECIMAL(10,2);

SELECT quantity_on_hand
INTO current_stock
FROM inventory
WHERE product_id = NEW.product_id;

-- Stops transaction if stock is not enough
IF current_stock < NEW.quantity THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Insufficient inventory stock';
END IF;
END$$

CREATE TRIGGER trg_deduct_inventory_after_sale
AFTER INSERT ON sale_items
FOR EACH ROW
BEGIN
DECLARE parent_status VARCHAR(20);

SELECT sale_status
INTO parent_status
FROM sales
WHERE sale_id = NEW.sale_id;

IF parent_status IN ('PAID', 'PENDING') THEN
UPDATE inventory
SET quantity_on_hand = quantity_on_hand - NEW.quantity,
last_updated = NOW()
WHERE product_id = NEW.product_id;
END IF;
END$$

DELIMITER ; 

DELIMITER $$
CREATE TRIGGER trg_restore_inventory_on_cancelled_sales
AFTER UPDATE ON sales
FOR EACH ROW
BEGIN
    IF NEW.sale_status = 'CANCELLED' AND OLD.sale_status != 'CANCELLED' THEN
        UPDATE inventory i
        JOIN   sale_items si ON si.product_id = i.product_id
        SET    i.quantity_on_hand = i.quantity_on_hand + si.quantity,
               i.last_updated     = NOW()
        WHERE  si.sale_id = NEW.sale_id;
    END IF;
END$$

-- INVENTORY MANAGEMENT BASED ON SUPPLIER ORDERS
DELIMITER $$
CREATE TRIGGER trg_import_supplier_stock
AFTER UPDATE ON supplier_orders
FOR EACH ROW
BEGIN

    -- run only when delivery is confirmed
    IF OLD.actual_delivery IS NULL
       AND NEW.actual_delivery IS NOT NULL
       AND NEW.order_status = 'RECEIVED' THEN

        -- add items into inventory
        UPDATE inventory i
        JOIN supplier_order_items soi
            ON i.product_id = soi.product_id
        SET i.quantity_on_hand = i.quantity_on_hand + soi.quantity,
            i.last_updated = NOW()
        WHERE soi.supplier_order_id = NEW.supplier_order_id;

    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_order_status_on_actual_delivery
BEFORE UPDATE ON supplier_orders
FOR EACH ROW
BEGIN
    IF OLD.actual_delivery IS NULL
       AND NEW.actual_delivery IS NOT NULL THEN

        SET NEW.order_status = 'RECEIVED';

    END IF;
END$$
DELIMITER ;





-- IMPORT AND EXPORT IN inventory_log
DELIMITER $$
CREATE TRIGGER trg_inventory_import
BEFORE UPDATE ON supplier_orders
FOR EACH ROW
BEGIN
    IF OLD.actual_delivery IS NULL
       AND NEW.actual_delivery IS NOT NULL
       AND NEW.order_status = 'RECEIVED' THEN

        INSERT INTO inventory_log (
            product_id,
            employee_id,
            supplier_order_id,
            sale_id,
            transaction_type,
            quantity,
            imported_at,
            exported_at
        )
        SELECT 
            soi.product_id,
            1004,
            NEW.supplier_order_id,
            NULL,
            'IMPORT',
            soi.quantity,
            NOW(),
            NULL
        FROM supplier_order_items soi
        WHERE soi.supplier_order_id = NEW.supplier_order_id;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_inventory_export
AFTER INSERT ON sale_items
FOR EACH ROW
BEGIN
    DECLARE v_sale_status VARCHAR(20) DEFAULT 'NOT FOUND';

    SELECT sale_status INTO v_sale_status
    FROM sales
    WHERE sale_id = NEW.sale_id
    LIMIT 1;

    IF v_sale_status IN ('PAID', 'PENDING') THEN
        INSERT INTO inventory_log (
            product_id,
            employee_id,
            supplier_order_id,
            sale_id,
            transaction_type,
            quantity,
            imported_at,
            exported_at
        )
        VALUES (
            NEW.product_id,
            1004,
            NULL,
            NEW.sale_id,
            'EXPORT',
            NEW.quantity,
            NULL,
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- LOYALTY POINTS MANAGEMENT
DELIMITER $$
CREATE TRIGGER trg_loyalty_points_strict
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_customer_id INT;
    DECLARE v_points INT;
    DECLARE v_has_active_card INT;
    DECLARE v_new_total DECIMAL(10,2);

    -- Always initialize
    SET NEW.points_awarded = 0;

    -- Only process successful payments
    IF NEW.payment_status = 'PAID' THEN

        -- Get customer from sale
        SELECT customer_id
        INTO v_customer_id
        FROM sales
        WHERE sale_id = NEW.sale_id;

        -- Compute points from payment
        SET v_points = FLOOR(NEW.amount_paid / 100);

        -- Check active loyalty card
        SELECT COUNT(*)
        INTO v_has_active_card
        FROM loyalty_card
        WHERE customer_id = v_customer_id
          AND card_status = 'ACTIVE';

        -- Apply only if card exists
        IF v_has_active_card > 0 THEN

            -- Compute NEW TOTAL explicitly (important fix)
            SELECT points_balance + v_points
            INTO v_new_total
            FROM loyalty_card
            WHERE customer_id = v_customer_id
              AND card_status = 'ACTIVE';

            -- Set awarded points
            SET NEW.points_awarded = v_points;

            -- Update loyalty card
            UPDATE loyalty_card
            SET points_balance = v_new_total,
                tier_level = CASE
                    WHEN v_new_total >= 5000 THEN 'GOLD'
                    WHEN v_new_total >= 1000 THEN 'SILVER'
                    ELSE 'BRONZE'
                END
            WHERE customer_id = v_customer_id
              AND card_status = 'ACTIVE';
        END IF;
    END IF;
END$$
DELIMITER ;
-- DEBT TRACKING MANAGEMENT
DELIMITER $$
CREATE TRIGGER trg_validate_debt_creation
BEFORE INSERT ON debt_tracker
FOR EACH ROW
BEGIN
    DECLARE payment_count INT;

    -- Check if the related sale has a payment
    -- with status PENDING or FAILED
    SELECT COUNT(*)
    INTO payment_count
    FROM payments
    WHERE sale_id = NEW.sale_id
      AND payment_status IN ('PENDING', 'FAILED');

    -- Prevent debt creation if no matching payment exists
    IF payment_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Debt records can only be created for sales with PENDING or FAILED payments.';
    END IF;

END$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_debt_status_flow
BEFORE UPDATE ON debt_tracker
FOR EACH ROW
BEGIN

    -- Prevent changes if already PAID
    IF OLD.debt_status = 'PAID' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'PAID debts cannot be modified or reopened.';
    END IF;
    -- Validate allowed transitions
    IF OLD.debt_status = 'PENDING' THEN
        IF NEW.debt_status NOT IN ('PAID', 'OVERDUE') THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'PENDING debt can only become PAID or OVERDUE.';
        END IF;
    ELSEIF OLD.debt_status = 'OVERDUE' THEN
        IF NEW.debt_status <> 'PAID' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'OVERDUE debt can only be marked as PAID.';
        END IF;
    END IF;
END$$
DELIMITER ;

-- EMPLOYEE MANAGEMENT
DELIMITER $$
CREATE TRIGGER trg_prevent_employee_delete
BEFORE DELETE ON employee
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Employees cannot be deleted. Set status to INACTIVE instead.';
END$$
DELIMITER ;






/*-------------------------------------------------------------------------------*/

/*
	SAMPLE DATAS
*/
/*
   PRODUCTS SECTION
*/
INSERT INTO rice_products 
(product_name, variety, unit, price_per_unit, product_status)
VALUES
('Prime Dinorado', 'Dinorado', '1 Sack', 1250.00, 'AVAILABLE'),
('Doña Maria', 'Sinandomeng', '1 Sack', 1180.00, 'AVAILABLE'),
('Perfect Jasmine', 'Jasmine', '1 Sack', 1370.00, 'AVAILABLE'),
('Coco Pandan', 'Pandan', '1 Sack', 1100.00, 'AVAILABLE'),
('Organic Brown Rice', 'Brown rice', '1 Sack', 1650.00, 'AVAILABLE');


/*
   SUPPLIERS SECTION
*/
INSERT INTO suppliers (supplier_name, contact_person, contact_number, email, address)
VALUES
('Golden Rice Trading', 'Ramon Villanueva', '09175649213', 'goldenrice@gmail.com', 'Brgy. Paliparan 1, Dasmariñas, Cavite'),
('Prime Grains Supply', 'Liza Fernandez', '09213487562', 'primegrains@yahoo.com', 'Brgy. Molino 3, Bacoor, Cavite'),
('Harvest Best Corp', 'Daniel Cruz', '09184572639', 'harvestbest@outlorder_dateook.com', 'Brgy. San Jose, Imus, Cavite'),
('Sunrise Rice Depot', 'Angela Ramos', '09327654891', 'sunriserice@gmail.com', 'Brgy. Salitran 2, Dasmariñas, Cavite'),
('Metro Grains Distributor', 'Victor Santos', '09192386475', 'metrograins@gmail.com', 'Brgy. Alapan 1, Imus, Cavite');


INSERT INTO supplier_orders
(supplier_id, expected_delivery, actual_delivery, order_status, payment_status)
VALUES
(1, '2026-06-03 08:00:00', '2026-07-03 07:45:00', 'RECEIVED', 'PAID'),
(2, '2026-06-10 09:30:00', NULL, 'PENDING', 'PARTIAL'),
(3, '2026-06-18 10:00:00', NULL, 'CANCELLED', 'UNPAID');


INSERT INTO supplier_order_items
(supplier_order_id, product_id, quantity, cost_per_unit, subtotal)
VALUES
(1, 1, 50.00, 1180.00, 59000.00),
(1, 2, 40.00, 1100.00, 44000.00),
(2, 3, 30.00, 1380.00, 41400.00),
(2, 4, 60.00, 1020.00, 61200.00),
(3, 5, 20.00, 1550.00, 31000.00);


/*
   CUSTOMERS SECTION
 */
INSERT INTO customers (full_name, customer_type, contact_number, address, email)
VALUES 
('John Carlo Sol', 'WALK-IN', '09183472659', 'Brgy. San Nicolas, Manila', 'john@gmail.com'),
('Alexandrei Bakingking', 'RESELLER', '09217649583', 'Brgy. Molino, Bacoor', 'alex@gmail.com'),
('Vince Balisbis', 'WALK-IN', '09194573826', 'Brgy. Banlic, Cabuyao', 'vince@gmail.com'),
('Maria Santos', 'RESELLER', '09328476195', 'Brgy. Alangilan, Batangas City', 'maria@gmail.com'),
('Carlos Mendoza', 'WALK-IN', '09176283945', 'Brgy. Salitran 4, Dasmariñas, Cavite', 'carlos@gmail.com');


INSERT INTO loyalty_card (customer_id, points_balance, issued_at, expiry_date, card_status)
VALUES
(1, 100, '2025-01-01', '2026-01-01', 'ACTIVE'),
(2, 500, '2025-02-01', '2026-02-01', 'ACTIVE'),
(3, 300, '2025-03-01', '2026-03-01', 'ACTIVE'),
(4, 800, '2025-04-01', '2026-04-01', 'ACTIVE'),
(5, 200, '2025-05-01', '2026-05-01', 'ACTIVE');


/*
   EMPLOYEES
*/
INSERT INTO employee (first_name, last_name, contact_number, email, position_role, hire_date, employee_status)
VALUES
('Maine', 'Mendoza', '09180000001', 'maine@gmail.com', 'Cashier', '2024-01-10', 'ACTIVE'),
('Alden', 'Recharge', '09180000002', 'alden@gmail.com', 'Manager', '2023-06-15', 'ACTIVE'),
('Armored', 'Clavio', '09180000003', 'armored@gmail.com', 'Sales Staff', '2024-02-20', 'ACTIVE'),
('James', 'Arthur', '09188800004', 'james@gmail.com', 'Inventory Staff', '2024-03-05', 'ACTIVE'),
('Dingdong', 'Dancesteps', '09180000005', 'dingdong@gmail.com', 'Cashier', '2023-11-25', 'ACTIVE');


/*
   SALES SECTION
 */
INSERT INTO sales (customer_id, employee_id, sale_date, sale_status)
VALUES
(1, 1001, NOW(), 'PAID'),
(2, 1002, NOW(), 'PENDING'),
(3, 1003, NOW(), 'PAID'),
(4, 1004, NOW(), 'CANCELLED'),
(5, 1005, NOW(), 'PAID');


INSERT INTO sale_items 
(sale_id, product_id, quantity, unit_price, subtotal)
VALUES 
(1, 1, 10, 1250.00, 12500.00),
(2, 2, 5, 1180.00, 5900.00),
(3, 3, 8, 1370.00, 10960.00),
(4, 4, 3, 1100.00, 3300.00),
(5, 5, 6, 1650.00, 9900.00);


INSERT INTO payments 
(sale_id, payment_method, amount_paid, reference_number, paid_at, payment_status)
VALUES
(1, 'CASH', 15000.00, 'REF001', NOW(), 'PAID'),
(2, 'COD', 9000.00, 'REF002', NOW(), 'PENDING'),
(3, 'COD', 11200.00, 'REF003', NOW(), 'PAID'),
(4, 'GCASH', 6000.00, 'REF004', NOW(), 'FAILED'),
(5, 'GCASH', 10200.00, 'REF005', NOW(), 'PAID');


INSERT INTO debt_tracker (customer_id, sale_id, amount_owed, amount_paid, due_date, debt_status)
VALUES
(2, 2, 1500, 500, '2026-06-01', 'PENDING'),
(4, 4, 1000, 200, '2026-05-20', 'OVERDUE');


/*
   INVENTORY SECTION
*/
INSERT INTO inventory(product_id, quantity_on_hand, reorder_level, last_updated, warehouse_location)
VALUES
(1, 80.00, 20.00, NOW(), 'Aniban Warehouse'),
(2, 100.00, 30.00, NOW(), 'Molino Warehouse'),
(3, 130.00, 50.00, NOW(), 'San Nicolas Warehouse'),
(4, 120.00, 40.00, NOW(), 'Almanza Uno Warehouse'),
(5, 220.00, 60.00, NOW(), 'Talon Dos Warehouse');

/*-------------------------------------------------------------------------------*/

-- PROCEDURES

-- Get customer debts
DELIMITER $$
CREATE PROCEDURE generate_customer_debts()
BEGIN
    SELECT
        c.customer_id,
        c.full_name,
        s.sale_id,
        d.amount_owed,
        d.amount_paid,
        d.debt_status,
        d.due_date
    FROM debt_tracker d
    JOIN customers c
        ON d.customer_id = c.customer_id
    JOIN sales s
        ON d.sale_id = s.sale_id
-- Shows only unsettled debts 
    WHERE d.debt_status IN ('PENDING', 'OVERDUE');
END$$
DELIMITER ;

-- Genarate sales report
DELIMITER $$
CREATE PROCEDURE generate_sales_report()
BEGIN
    SELECT 
        s.sale_id,
        c.full_name AS customer_name,
        CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
        s.sale_date,
        s.sale_status,
-- Cancelled sales are reported with zero revenue 
        CASE 
            WHEN s.sale_status = 'CANCELLED' THEN 0
            ELSE COALESCE(SUM(p.amount_paid), 0)
        END AS total_paid

    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN employee e
        ON s.employee_id = e.employee_id
    LEFT JOIN payments p
        ON s.sale_id = p.sale_id

    GROUP BY 
        s.sale_id,
        c.full_name,
        CONCAT(e.first_name, ' ', e.last_name),
        s.sale_date,
        s.sale_status;
END $$
DELIMITER ;

/*-------------------------------------------------------------------------------*/

/*
	ADVANCE QUERIES
*/

-- BEST-SELLING RICE
SELECT 
    rp.product_id,
    rp.product_name,
    rp.variety,
    SUM(si.quantity) AS total_quantity_sold,
    SUM(si.quantity * si.unit_price) AS total_sales
FROM sale_items si
JOIN rice_products rp
    ON si.product_id = rp.product_id
GROUP BY rp.product_id, rp.product_name, rp.variety
ORDER BY total_quantity_sold DESC;

-- LOW STOCK AND CURRENT STOCK
SELECT 
    i.inventory_id,
    rp.product_name,
    rp.variety,
    i.quantity_on_hand AS current_stock,
    i.reorder_level,
    i.warehouse_location,
    i.last_updated,
 -- Indicates whether stock needs replenishment    
 CASE
        WHEN i.quantity_on_hand <= i.reorder_level 
        THEN 'LOW STOCK'
        ELSE 'SUFFICIENT'
    END AS stock_status
FROM inventory i
JOIN rice_products rp
    ON i.product_id = rp.product_id
ORDER BY 
	i.quantity_on_hand ASC,
	stock_status DESC;    

-- -Supplier order
-- This query displays supplier order information by combining supplier details and supplier order records to monitor deliveries, order progress, and payment status.
SELECT 
    s.supplier_name,
    so.order_date,
    so.expected_delivery,
    so.actual_delivery,
    so.order_status,
    so.payment_status
FROM supplier_orders so
JOIN suppliers s ON so.supplier_id = s.supplier_id;
-- JOIN combines supplier data and order records using supplier_id
-- – Sales by employee
SELECT
    employee.employee_id,
    employee.first_name,
    employee.last_name,
    COUNT(sales.sale_id) AS total_sales_transactions,
    SUM(payments.amount_paid) AS total_sales_amount
FROM employee
JOIN sales
    ON employee.employee_id = sales.employee_id
JOIN payments
    ON sales.sale_id = payments.sale_id
-- Includes only successfully paid transactions 
WHERE payments.payment_status = 'PAID'
GROUP BY
    employee.employee_id,
    employee.first_name,
    employee.last_name
ORDER BY total_sales_amount DESC;

-- Supplier Performance Monitoring
SELECT
    s.supplier_name,
    COUNT(DISTINCT so.supplier_order_id) AS total_orders,
    COALESCE(SUM(oi.total_spent), 0) AS total_amount_spent,
    SUM(oi.is_on_time) AS on_time_deliveries,
    SUM(oi.is_late) AS late_deliveries,
    SUM(oi.is_pending) AS pending_deliveries,
    ROUND(
        (SUM(oi.is_on_time) / NULLIF(COUNT(DISTINCT so.supplier_order_id), 0)) * 100,
    2) AS on_time_percentage
FROM suppliers s
LEFT JOIN supplier_orders so
    ON s.supplier_id = so.supplier_id
LEFT JOIN (
    SELECT
        supplier_order_id,
        SUM(subtotal) AS total_spent,
        CASE 
            WHEN actual_delivery IS NULL THEN 0 ELSE 1 
        END AS is_checked,
        CASE 
            WHEN actual_delivery IS NOT NULL
             AND actual_delivery <= expected_delivery THEN 1 ELSE 0
        END AS is_on_time,
        CASE 
            WHEN actual_delivery IS NOT NULL
             AND actual_delivery > expected_delivery THEN 1 ELSE 0
        END AS is_late,
        CASE 
            WHEN actual_delivery IS NULL THEN 1 ELSE 0
        END AS is_pending
    FROM supplier_orders
    LEFT JOIN supplier_order_items USING (supplier_order_id)
    GROUP BY supplier_order_id, actual_delivery, expected_delivery
) oi
ON so.supplier_order_id = oi.supplier_order_id
GROUP BY s.supplier_name
ORDER BY total_amount_spent DESC;

/*-------------------------------------------------------------------------------*/
/*
SECURITY ROLES
*/
-- This section creates database user accounts and assigns different access permissions where the admin has full database control while staff users are limited to viewing, inserting, and updating records only.
CREATE USER 'admin_user'@'localhost'
IDENTIFIED BY 'admin123';

-- Creates a staff account.
-- Staff users are only allowed to manage records.
CREATE USER 'staff_user'@'localhost'
IDENTIFIED BY 'staff123';

-- Gives the admin full access to all tables,
-- including adding, editing, deleting, and managing structure.
GRANT ALL PRIVILEGES
ON rice_supplier.*
TO 'admin_user'@'localhost';

-- Gives staff limited access only.
-- Staff can view, add, and update data
-- but cannot delete records or change the database structure.
GRANT SELECT, INSERT, UPDATE
ON rice_supplier.*
TO 'staff_user'@'localhost';

-- Applies and saves all privilege changes immediately.
FLUSH PRIVILEGES;