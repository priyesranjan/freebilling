const { Client } = require('pg');
require('dotenv').config();

const client = new Client({
  connectionString: process.env.DATABASE_URL,
});

async function patch() {
  try {
    await client.connect();
    console.log("Connected to DB for patching...");

    // Update Businesses
    await client.query(`
      ALTER TABLE businesses 
      ADD COLUMN IF NOT EXISTS business_type VARCHAR(100),
      ADD COLUMN IF NOT EXISTS website_slug VARCHAR(255) UNIQUE,
      ADD COLUMN IF NOT EXISTS website_config JSONB DEFAULT '{}'
    `);

    // Update Products
    await client.query(`
      ALTER TABLE products 
      ADD COLUMN IF NOT EXISTS mrp DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS selling_price DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS discount_percent DECIMAL(5, 2) DEFAULT 0
    `);

    console.log("Database patched successfully!");
  } catch (err) {
    console.error("Patch Error:", err);
  } finally {
    await client.end();
  }
}

patch();
