-- LLD 5.2 — schema
CREATE TABLE products (
  product_id INT IDENTITY PRIMARY KEY,
  sku NVARCHAR(20) NOT NULL UNIQUE,
  name NVARCHAR(200) NOT NULL,
  price DECIMAL(10,2) NOT NULL
);

CREATE TABLE stock (
  sku NVARCHAR(20) PRIMARY KEY REFERENCES products(sku),
  quantity_on_hand INT NOT NULL DEFAULT 0,
  updated_at DATETIME2 DEFAULT SYSUTCDATETIME()
);

-- LLD 5.2 — seed data
INSERT INTO products (sku, name, price) VALUES
  ('SKU-100', 'Wireless Mouse', 499.00),
  ('SKU-200', 'Mechanical Keyboard', 2499.00),
  ('SKU-300', 'USB-C Hub', 1299.00);

INSERT INTO stock (sku, quantity_on_hand) VALUES
  ('SKU-100', 50), ('SKU-200', 20), ('SKU-300', 35);
