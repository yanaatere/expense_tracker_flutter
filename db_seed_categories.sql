-- Seed categories and sub-categories to match Flutter FE local IDs.
-- Run once on the BE database. IDs are FE-owned; the FK on transactions
-- is dropped (or this seed makes it satisfy without an FK altogether).
--
-- After running this, the BE can:
--   SELECT * FROM transactions WHERE category_id = 10   -- Food and Beverage
--   GROUP BY category_id + JOIN categories for labels

-- ── 1. Remove FK constraint (if it exists) ────────────────────────────────────
-- PostgreSQL: look up the constraint name and drop it.
-- Adjust table/column names to match your schema.
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_category_id_fkey;
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_sub_category_id_fkey;

-- ── 2. Seed categories ────────────────────────────────────────────────────────
-- type column: 'income' | 'expense'
-- ON CONFLICT DO NOTHING is safe to re-run.

INSERT INTO categories (id, name, type) VALUES
  -- Income
  (1,  'Active income',    'income'),
  (2,  'Side Hustle',      'income'),
  (3,  'Business',         'income'),
  (4,  'Investment',       'income'),
  -- Expense
  (5,  'Bills',            'expense'),
  (6,  'Education',        'expense'),
  (7,  'Entertainment',    'expense'),
  (8,  'Family and Friends','expense'),
  (9,  'Financial',        'expense'),
  (10, 'Food and Beverage','expense'),
  (11, 'Health',           'expense'),
  (12, 'Personal',         'expense'),
  (13, 'Pet',              'expense'),
  (14, 'Service',          'expense'),
  (15, 'Shop',             'expense'),
  (16, 'Transport',        'expense'),
  (17, 'Vacation',         'expense')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, type = EXCLUDED.type;

-- ── 3. Seed sub-categories ────────────────────────────────────────────────────

INSERT INTO sub_categories (id, category_id, name) VALUES
  -- Active income (1)
  (101, 1, 'Salary'),
  (102, 1, 'Bonus'),
  -- Side Hustle (2)
  (103, 2, 'Freelancing'),
  (104, 2, 'Consultation'),
  (105, 2, 'Affiliate'),
  (106, 2, 'Ads'),
  -- Business (3)
  (107, 3, 'Product sales'),
  (108, 3, 'Reseller'),
  -- Investment (4)
  (109, 4, 'Interest'),
  (110, 4, 'Dividends'),
  (111, 4, 'Capital gain'),
  (112, 4, 'Rental'),
  -- Bills (5)
  (201, 5, 'Electricity'),
  (202, 5, 'Environmental Fees'),
  (203, 5, 'House'),
  (204, 5, 'Installment'),
  (205, 5, 'Insurance'),
  (206, 5, 'Paylater'),
  (207, 5, 'Rent'),
  (208, 5, 'Subscription'),
  (209, 5, 'Internet'),
  (210, 5, 'Water'),
  -- Education (6)
  (211, 6, 'Course'),
  (212, 6, 'School'),
  (213, 6, 'Stationery'),
  (214, 6, 'Book'),
  (215, 6, 'College'),
  -- Entertainment (7)
  (216, 7, 'Cinema'),
  (217, 7, 'Concert'),
  (218, 7, 'Hang out'),
  (219, 7, 'Karaoke'),
  (220, 7, 'Photobox'),
  (221, 7, 'Streaming'),
  (222, 7, 'Games'),
  -- Family and Friends (8)
  (223, 8, 'Baby Gear'),
  (224, 8, 'Childcare'),
  (225, 8, 'Loan'),
  (226, 8, 'Present'),
  (227, 8, 'Transfer'),
  -- Financial (9)
  (228, 9, 'Charity'),
  (229, 9, 'Cryptocurrency'),
  (230, 9, 'Top Up'),
  (231, 9, 'Tax'),
  -- Food and Beverage (10)
  (232, 10, 'Breakfast'),
  (233, 10, 'Cafe'),
  (234, 10, 'Dinner'),
  (235, 10, 'Lunch'),
  (236, 10, 'Street Food'),
  -- Health (11)
  (237, 11, 'Clinic'),
  (238, 11, 'Doctor Consultation'),
  (239, 11, 'Health Insurance'),
  (240, 11, 'Mental Health'),
  (241, 11, 'Pharmacy'),
  -- Personal (12)
  (242, 12, 'Grooming'),
  (243, 12, 'Gym'),
  (244, 12, 'Hobby'),
  (245, 12, 'Salon'),
  (246, 12, 'Skincare'),
  (247, 12, 'Spa'),
  (248, 12, 'Yoga Class'),
  -- Pet (13)
  (249, 13, 'Pet Accessories'),
  (250, 13, 'Pet Care'),
  (251, 13, 'Pet Food'),
  (252, 13, 'Pet Grooming'),
  (253, 13, 'Toys'),
  -- Service (14)
  (254, 14, 'Car Maintenance'),
  (255, 14, 'Cleaning Service'),
  (256, 14, 'Delivery Service'),
  (257, 14, 'Electronics Repair'),
  (258, 14, 'Furniture Maintenance'),
  (259, 14, 'Motorcycle Maintenance'),
  (260, 14, 'Online Delivery'),
  -- Shop (15)
  (261, 15, 'Beauty'),
  (262, 15, 'Electronics'),
  (263, 15, 'Furniture'),
  (264, 15, 'Gadgets'),
  (265, 15, 'Grocery'),
  (266, 15, 'Kitchenware'),
  (267, 15, 'Online Shop'),
  (268, 15, 'Tools'),
  -- Transport (16)
  (269, 16, 'Bus'),
  (270, 16, 'Flight'),
  (271, 16, 'Fuel'),
  (272, 16, 'Online Transportation'),
  (273, 16, 'Parking'),
  (274, 16, 'Ship'),
  (275, 16, 'Taxi'),
  (276, 16, 'Toll Road'),
  (277, 16, 'Train'),
  (278, 16, 'Vehicle Charging'),
  -- Vacation (17)
  (279, 17, 'Activity'),
  (280, 17, 'Culinary'),
  (281, 17, 'Documentation'),
  (282, 17, 'Souvenir'),
  (283, 17, 'Ticketing & Sightseeing'),
  (284, 17, 'Tour Guide'),
  (285, 17, 'Transportation'),
  (286, 17, 'Visa'),
  (287, 17, 'Hotel')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, category_id = EXCLUDED.category_id;

-- ── 4. Reset sequences so next auto-generated id doesn't collide ──────────────
-- Adjust sequence names to match your schema.
SELECT setval('categories_id_seq',    (SELECT MAX(id) FROM categories));
SELECT setval('sub_categories_id_seq', (SELECT MAX(id) FROM sub_categories));

-- ── 5. Query examples ─────────────────────────────────────────────────────────
-- Transactions by category:
--   SELECT c.name, COUNT(*), SUM(t.amount)
--   FROM transactions t
--   JOIN categories c ON c.id = t.category_id
--   WHERE t.wallet_id = 1
--   GROUP BY c.id, c.name;

-- Filter by category:
--   GET /api/transactions?category_id=10   → Food and Beverage
--   GET /api/transactions?category_id=5    → Bills
