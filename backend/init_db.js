const db = require('./db');

const initSql = `
-- Drop tables if they exist for clean init (careful in production!)
-- DROP TABLE IF EXISTS invoice_lines, invoices, expenses, parties, products, businesses CASCADE;

CREATE TABLE IF NOT EXISTS businesses (
  id VARCHAR(255) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
  id VARCHAR(255) PRIMARY KEY,
  business_id VARCHAR(255) REFERENCES businesses(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  mrp DECIMAL(10, 2) DEFAULT 0,
  selling_price DECIMAL(10, 2) DEFAULT 0,
  codes JSONB DEFAULT '[]',
  tax_rate VARCHAR(50) DEFAULT 'exempt',
  current_stock DECIMAL(10, 2) DEFAULT 0,
  low_stock_level DECIMAL(10, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parties (
  id VARCHAR(255) PRIMARY KEY,
  business_id VARCHAR(255) REFERENCES businesses(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  type VARCHAR(50) DEFAULT 'customer',
  balance DECIMAL(15, 2) DEFAULT 0.0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS invoices (
  id VARCHAR(255) PRIMARY KEY,
  business_id VARCHAR(255) REFERENCES businesses(id) ON DELETE CASCADE,
  customer_name VARCHAR(255),
  customer_phone VARCHAR(20),
  total DECIMAL(15, 2) NOT NULL,
  payment_mode VARCHAR(50) DEFAULT 'cash',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS invoice_lines (
  id SERIAL PRIMARY KEY,
  invoice_id VARCHAR(255) REFERENCES invoices(id) ON DELETE CASCADE,
  product_id VARCHAR(255) REFERENCES products(id) ON DELETE SET NULL,
  product_name VARCHAR(255),
  quantity DECIMAL(10, 2) NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  final_amount DECIMAL(15, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS expenses (
  id VARCHAR(255) PRIMARY KEY,
  business_id VARCHAR(255) REFERENCES businesses(id) ON DELETE CASCADE,
  amount DECIMAL(15, 2) NOT NULL,
  category VARCHAR(100) NOT NULL,
  payment_mode VARCHAR(50) DEFAULT 'cash',
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
`;

async function initDb() {
  try {
    console.log('Connecting to database and running schema...');
    await db.query(initSql);
    console.log('Schema created successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Error creating schema:', err);
    process.exit(1);
  }
}

initDb();
