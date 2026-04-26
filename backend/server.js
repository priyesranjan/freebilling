const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const db = require('./db');
const http = require('http');
const axios = require('axios');
const path = require('path');
const { Server } = require('socket.io');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const multer = require('multer');

require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.use(cors());
app.use(express.json());
app.use('/web', express.static(path.join(__dirname, 'public')));

// SPA routing for /web
app.get('/web/*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const JWT_SECRET = process.env.JWT_SECRET || 'erp_bill_super_secret_key';
const TWO_FACTOR_API_KEY = 'a4f42790-1574-11f1-bcb0-0200cd936042';

// Cloudflare R2 Config
const s3 = new S3Client({
  region: 'auto',
  endpoint: 'https://5c4ce3f441e1aba0ff794665e17df31b.r2.cloudflarestorage.com',
  credentials: {
    accessKeyId: 'b0e9f0b5102c1adaf5e64580f3e9b087',
    secretAccessKey: '01cf49dc12389495d7183fe9b16c9d98020163db51286b4f960e35b81c17d6cd',
  },
});
const upload = multer({ storage: multer.memoryStorage() });

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// WebSocket Authentication & Room Joining
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) return next(new Error('Authentication error'));
  
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return next(new Error('Authentication error'));
    socket.user = user;
    next();
  });
});

io.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id} for business: ${socket.user.businessId}`);
  // Join a room specifically for this business
  socket.join(socket.user.businessId);

  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}`);
  });
});

// --- AUTH ENDPOINTS ---

app.post('/api/auth/send-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone is required' });
  
  try {
    // 2Factor.in Send OTP (6-digit AUTOGEN)
    const url = `https://2factor.in/API/V1/${TWO_FACTOR_API_KEY}/SMS/${phone}/AUTOGEN`;
    const response = await axios.get(url);
    
    if (response.data.Status === 'Success') {
      res.json({ success: true, sessionId: response.data.Details });
    } else {
      throw new Error(response.data.Details);
    }
  } catch (err) {
    console.error("2Factor Error:", err.message);
    // Fallback for development if needed, but here we want real SMS
    res.status(500).json({ error: 'Failed to send SMS', details: err.message });
  }
});

app.post('/api/auth/send-otp-call', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone is required' });
  
  try {
    // 2Factor.in Voice OTP
    const url = `https://2factor.in/API/V1/${TWO_FACTOR_API_KEY}/VOICE/${phone}/AUTOGEN`;
    const response = await axios.get(url);
    
    if (response.data.Status === 'Success') {
      res.json({ success: true, sessionId: response.data.Details });
    } else {
      throw new Error(response.data.Details);
    }
  } catch (err) {
    console.error("2Factor Voice Error:", err.message);
    res.status(500).json({ error: 'Failed to send Voice OTP', details: err.message });
  }
});

app.post('/api/auth/verify-otp', async (req, res) => {
  const { phone, otp, sessionId, name, businessType, category, logoUrl } = req.body;
  if (!phone || !otp || !sessionId) return res.status(400).json({ error: 'Phone, OTP and SessionId are required' });
  
  try {
    // 2Factor.in Verify OTP
    const url = `https://2factor.in/API/V1/${TWO_FACTOR_API_KEY}/SMS/VERIFY/${sessionId}/${otp}`;
    const response = await axios.get(url);
    
    if (response.data.Status !== 'Success') {
      return res.status(401).json({ error: 'Invalid OTP' });
    }
    
    let result = await db.query('SELECT * FROM businesses WHERE phone = $1', [phone]);
    let user;
    if (result.rows.length === 0) {
      const businessId = 'BUS-' + Date.now();
      const bName = name || 'My Business';
      const bType = businessType || 'retail';
      
      const config = logoUrl ? JSON.stringify({ logo_url: logoUrl }) : '{}';

      await db.query(
        'INSERT INTO businesses (id, name, phone, password, business_type, website_config) VALUES ($1, $2, $3, $4, $5, $6)',
        [businessId, bName, phone, 'otp-auth', bType, config]
      );
      user = { id: businessId, name: bName, phone, business_type: bType };
    } else {
      user = result.rows[0];
    }
    
    const token = jwt.sign({ businessId: user.id, name: user.name, phone: user.phone }, JWT_SECRET);
    res.json({ token, business: user });
  } catch (err) {
    console.error("Verify OTP Error:", err);
    res.status(500).json({ error: 'Invalid OTP or Service Error', details: err.message });
  }
});

app.post('/api/auth/google', async (req, res) => {
  const { email, name } = req.body;
  if (!email) return res.status(400).json({ error: 'Email is required' });

  try {
    let result = await db.query('SELECT * FROM businesses WHERE phone = $1', [email]);
    let user;
    if (result.rows.length === 0) {
      const businessId = 'BUS-' + Date.now();
      const bName = name || 'My Business';
      await db.query(
        'INSERT INTO businesses (id, name, phone, password) VALUES ($1, $2, $3, $4)',
        [businessId, bName, email, 'google-auth']
      );
      user = { id: businessId, name: bName, phone: email };
    } else {
      user = result.rows[0];
    }
    
    const token = jwt.sign({ businessId: user.id, name: user.name, phone: user.phone }, JWT_SECRET);
    res.json({ token, business: user });
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

app.put('/api/businesses/onboard', authenticateToken, async (req, res) => {
  const { name, businessType, websiteSlug } = req.body;
  try {
    const result = await db.query(
      `UPDATE businesses SET name = $1, business_type = $2, website_slug = $3 WHERE id = $4 RETURNING *`,
      [name, businessType, websiteSlug, req.user.businessId]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Failed to update onboarding info', details: err.message });
  }
});

app.post('/api/upload-logo', upload.single('logo'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  const fileName = `logos/${Date.now()}_${req.file.originalname}`;
  
  try {
    const command = new PutObjectCommand({
      Bucket: 'freebilling',
      Key: fileName,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
      ACL: 'public-read', // Ensure bucket allows public read if needed
    });

    await s3.send(command);

    // Using public R2 domain or custom domain if mapped. 
    // Assuming bucket allows public access via default dev URL or we can construct it.
    // Replace with your actual public R2 domain if you mapped one.
    const publicUrl = `https://pub-your-r2-public-url.r2.dev/${fileName}`; 

    res.json({ success: true, url: publicUrl, key: fileName });
  } catch (err) {
    console.error("R2 Upload Error:", err);
    res.status(500).json({ error: 'Failed to upload to R2', details: err.message });
  }
});

app.get('/api/products', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM products WHERE business_id = $1 ORDER BY created_at DESC', [req.user.businessId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

app.post('/api/products', authenticateToken, async (req, res) => {
  const { id, name, mrp, selling_price, codes, tax_rate, current_stock, low_stock_level } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO products (id, business_id, name, mrp, selling_price, price, codes, tax_rate, current_stock, low_stock_level) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
       ON CONFLICT (id) DO UPDATE SET 
         name = EXCLUDED.name, 
         mrp = EXCLUDED.mrp, 
         selling_price = EXCLUDED.selling_price, 
         price = EXCLUDED.price, 
         codes = EXCLUDED.codes, 
         tax_rate = EXCLUDED.tax_rate, 
         current_stock = EXCLUDED.current_stock, 
         low_stock_level = EXCLUDED.low_stock_level
       RETURNING *`,
      [id, req.user.businessId, name, mrp || 0, selling_price || 0, selling_price || 0, JSON.stringify(codes || []), tax_rate || 'exempt', current_stock || 0, low_stock_level || 0]
    );
    
    io.to(req.user.businessId).emit('sync_event', { type: 'Product', action: 'insert', data: result.rows[0] });
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error("Save Product Error:", err.message);
    res.status(500).json({ error: 'Database error', details: err.message });
  }
});

// --- KHATA (PARTIES) ENDPOINTS ---

app.get('/api/khata', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM parties WHERE business_id = $1 ORDER BY name ASC', [req.user.businessId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

app.post('/api/khata', authenticateToken, async (req, res) => {
  const { id, name, phone, type, balance } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO parties (id, business_id, name, phone, type, balance) 
       VALUES ($1, $2, $3, $4, $5, $6) 
       ON CONFLICT (id) DO UPDATE SET 
         name = EXCLUDED.name, 
         phone = EXCLUDED.phone, 
         type = EXCLUDED.type, 
         balance = EXCLUDED.balance
       RETURNING *`,
      [id, req.user.businessId, name, phone, type || 'customer', balance || 0]
    );
    
    io.to(req.user.businessId).emit('sync_event', { type: 'PartyRecord', action: 'upsert', data: result.rows[0] });
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

// --- INVOICES ENDPOINTS ---

app.get('/api/invoices', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM invoices WHERE business_id = $1 ORDER BY created_at DESC', [req.user.businessId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

app.post('/api/invoices', authenticateToken, async (req, res) => {
  const { id, customer_name, customer_phone, total, payment_mode } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO invoices (id, business_id, customer_name, customer_phone, total, payment_mode) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [id, req.user.businessId, customer_name, customer_phone, total, payment_mode]
    );
    
    io.to(req.user.businessId).emit('sync_event', { type: 'InvoiceRecord', action: 'insert', data: result.rows[0] });
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

const PORT = process.env.PORT || 3000;

async function runPatch() {
  try {
    // Patch Businesses
    await db.query(`
      ALTER TABLE businesses 
      ADD COLUMN IF NOT EXISTS business_type VARCHAR(100),
      ADD COLUMN IF NOT EXISTS website_slug VARCHAR(255) UNIQUE,
      ADD COLUMN IF NOT EXISTS category VARCHAR(100),
      ADD COLUMN IF NOT EXISTS logo_url VARCHAR(500),
      ADD COLUMN IF NOT EXISTS website_config JSONB DEFAULT '{}'
    `);
    // Patch Products
    await db.query(`
      ALTER TABLE products 
      ADD COLUMN IF NOT EXISTS mrp DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS selling_price DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS discount_percent DECIMAL(5, 2) DEFAULT 0
    `);
    console.log("Database Auto-Patched!");
  } catch (err) {
    console.error("Auto-Patch Error:", err);
  }
}

server.listen(PORT, async () => {
  await runPatch();
  console.log(`ERP Backend API & WebSockets running on port ${PORT}`);
});
