const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const db = require('./db');
const http = require('http');
const axios = require('axios');
const path = require('path');
const { Server } = require('socket.io');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const multer = require('multer');
const fs = require('fs');

require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.use(cors());
app.use(express.json());

// Request logging
app.use((req, res, next) => {
  console.log(`[REQUEST] ${req.method} ${req.url}`);
  next();
});

app.use('/web', express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// SPA routing for /web
app.get('/web/*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ── Health Check ────────────────────────────────────────────────
const SERVICE_VERSION = '1.4.0';
function healthPayload() {
  return {
    status: 'ok',
    service: 'Dukan Bill API',
    version: SERVICE_VERSION,
    timestamp: new Date().toISOString(),
  };
}
app.get('/api/health', (req, res) => res.json(healthPayload()));
app.get('/health', (req, res) => res.json(healthPayload()));

// ── Business Storefront (Public, No Auth) ────────────────────────
const shopTemplate = fs.readFileSync(path.join(__dirname, 'views', 'shop.html'), 'utf8');
const invoiceTemplate = fs.readFileSync(path.join(__dirname, 'views', 'invoice.html'), 'utf8');

app.get(['/:slug', '/shop/:slug'], async (req, res, next) => {
  try {
    const { slug } = req.params;
    if (['api', 'uploads', 'web', 'health', 'favicon.ico'].includes(slug) || slug.includes('.')) {
      return next();
    }
    const theme = req.query.theme || 'modern'; // Support multiple themes: modern, dark, rose

    const bizResult = await db.query(
      `SELECT * FROM businesses WHERE website_slug = $1 OR LOWER(REPLACE(name, ' ', '-')) = $1 LIMIT 1`,
      [slug.toLowerCase()]
    );
    if (bizResult.rows.length === 0) {
      return res.status(404).send(`
        <html><body style="font-family:sans-serif;text-align:center;padding:60px;background:#f8fafc;color:#1e293b">
          <div style="font-size:64px;margin-bottom:20px">🏪</div>
          <h2 style="font-weight:800;font-size:24px">Business Not Found</h2>
          <p style="color:#64748b;margin:10px 0 20px">No store found at this link. Please check the URL.</p>
          <a href="/" style="background:#4f46e5;color:white;padding:12px 24px;border-radius:12px;text-decoration:none;font-weight:700">← Back to Dukan Bill</a>
        </body></html>`);
    }
    const biz = bizResult.rows[0];

    const prodsResult = await db.query(
      `SELECT id, name, selling_price as "sellingPrice", mrp, current_stock as "currentStock", 
              low_stock_level as "lowStockAlertLevel", COALESCE(category, 'General') as category, codes, tax_rate as "taxRate"
       FROM products WHERE business_id = $1 ORDER BY name`,
      [biz.id]
    );

    const phone = (biz.phone || '').replace(/\D/g, '');
    const initial = (biz.name || 'B')[0].toUpperCase();
    const city = biz.city || biz.address || '';

    const html = shopTemplate
      .replace(/{{businessName}}/g, biz.name || 'Business')
      .replace(/{{initial}}/g, initial)
      .replace(/{{city}}/g, city)
      .replace(/{{phone}}/g, biz.phone || '')
      .replace(/{{rawPhone}}/g, phone)
      .replace(/theme-modern/g, `theme-${req.query.theme || biz.online_store_theme || 'modern'}`)
      .replace('{{businessJson}}', JSON.stringify({ businessName: biz.name, phone, gmb_location_id: biz.gmb_location_id }))
      .replace('{{productsJson}}', JSON.stringify(prodsResult.rows));

    res.send(html);
  } catch (err) {
    console.error('Shop route error:', err);
    res.status(500).send('Something went wrong. Please try again.');
  }
});

// ── Public Shop API (JSON) ────────────────────────────────────────
app.get('/api/shop/:slug', async (req, res) => {
  try {
    const { slug } = req.params;
    const bizResult = await db.query(
      `SELECT id, name, phone, city, address, gstin, gmb_location_id, website_slug
       FROM businesses 
       WHERE website_slug = $1 OR LOWER(REPLACE(name, ' ', '-')) = $1 LIMIT 1`,
      [slug.toLowerCase()]
    );
    if (bizResult.rows.length === 0) return res.status(404).json({ error: 'Business not found' });
    const biz = bizResult.rows[0];

    const prodsResult = await db.query(
      'SELECT id, name, selling_price as "sellingPrice", mrp, current_stock as "currentStock", low_stock_level as "lowStockAlertLevel", codes, tax_rate as "taxRate" FROM products WHERE business_id = $1',
      [biz.id]
    );
    res.json({ business: biz, products: prodsResult.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Public Store Online Order / Service Booking API ────────────────────────
app.post('/api/shop/:slug/orders', async (req, res) => {
  try {
    const { slug } = req.params;
    const { customerName, customerPhone, items, totalAmount, note, orderType } = req.body;
    
    const bizResult = await db.query(
      `SELECT id FROM businesses WHERE website_slug = $1 OR LOWER(REPLACE(name, ' ', '-')) = $1 LIMIT 1`,
      [slug.toLowerCase()]
    );
    if (bizResult.rows.length === 0) return res.status(404).json({ error: 'Store not found' });
    const bizId = bizResult.rows[0].id;

    const ordId = 'ORD-' + Date.now();
    const orderLines = (items && items.length > 0) ? items : [{ name: note || 'Service Request', quantity: 1, rate: totalAmount || 0, total: totalAmount || 0 }];

    const result = await db.query(
      `INSERT INTO invoices (id, business_id, customer_name, customer_phone, total, payment_mode, invoice_type, lines, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW()) RETURNING *`,
      [ordId, bizId, customerName || 'Online Customer', customerPhone || '', totalAmount || 0, 'online', (orderType || 'online_order').toLowerCase(), JSON.stringify(orderLines)]
    );

    if (io) {
      io.to(bizId).emit('sync_event', { type: 'InvoiceRecord', action: 'insert', data: result.rows[0] });
    }

    res.json({ success: true, message: 'Order submitted successfully!', orderId: ordId });
  } catch (e) {
    console.error('Order API error:', e);
    res.status(500).json({ error: 'Failed to submit order' });
  }
});


const JWT_SECRET = process.env.JWT_SECRET || 'erp_bill_super_secret_key';
const TWO_FACTOR_API_KEY = process.env.TWO_FACTOR_API_KEY || 'a4f42790-1574-11f1-bcb0-0200cd936042';

// Local Storage Config for Multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = './uploads/logos';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '_' + file.originalname);
  }
});
const upload = multer({ storage });

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

app.post(['/api/send-otp', '/api/auth/send-otp'], async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone number is required' });

  try {
    // 2Factor.in Send OTP (AUTOGEN) using template name configured in 2Factor
    const url = `https://2factor.in/API/V1/${TWO_FACTOR_API_KEY}/SMS/${phone}/AUTOGEN/OTP1`;
    const response = await axios.get(url);
    
    if (response.data.Status === 'Success') {
      console.log(`[API LOG] SMS OTP Sent to ${phone}. Session: ${response.data.Details}`);
      res.json({ success: true, sessionId: response.data.Details });
    } else {
      throw new Error(response.data.Details);
    }
  } catch (err) {
    console.error("[API ERROR] 2Factor Error:", err.message);
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
      const slug = name ? name.toLowerCase().replace(/\s+/g, '-') + '-' + Math.floor(Math.random()*1000) : null;
      
      const insertRes = await db.query(
        'INSERT INTO businesses (id, name, phone, business_type, category, logo_url, website_slug) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
        [businessId, name || 'My Business', phone, businessType || 'General', category || 'Retail', logoUrl || null, slug]
      );
      user = insertRes.rows[0];
    } else {
      user = result.rows[0];
    }
    
    const token = jwt.sign({ businessId: user.id, name: user.name, phone: user.phone }, JWT_SECRET);
    console.log(`[API LOG] Auth Success: ${phone} (Business: ${user.name})`);
    res.json({ token, business: user });
  } catch (err) {
    console.error("[API ERROR] Verify OTP Error:", err);
    res.status(500).json({ error: 'Invalid OTP or Service Error', details: err.message });
  }
});

// --- NEW: LOGIN WITH PASSWORD ---
app.post('/api/login', async (req, res) => {
  const { phone, password } = req.body;
  if (!phone || !password) return res.status(400).json({ error: 'Phone and Password are required' });

  try {
    const result = await db.query('SELECT * FROM businesses WHERE phone = $1', [phone]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Account does not exist. Please Sign Up.' });

    const user = result.rows[0];
    
    // Check if the user was created via OTP/Google without a password
    if (!user.password || user.password === 'google-auth') {
        return res.status(401).json({ error: 'Account uses OTP or Google Auth. Please login via those methods or reset password.' });
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) return res.status(401).json({ error: 'Incorrect password' });

    const token = jwt.sign({ businessId: user.id, name: user.name, phone: user.phone }, JWT_SECRET);
    res.json({ token, business: user });
  } catch (err) {
    console.error('Login Error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --- NEW: REGISTER WITH PASSWORD ---
app.post('/api/register', async (req, res) => {
  const { phone, password, name, businessType, category } = req.body;
  if (!phone || !password) return res.status(400).json({ error: 'Phone and Password are required' });

  try {
    const existing = await db.query('SELECT * FROM businesses WHERE phone = $1', [phone]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'An account with this phone number already exists.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const businessId = 'BUS-' + Date.now();
    const slug = name ? name.toLowerCase().replace(/\\s+/g, '-') + '-' + Math.floor(Math.random()*1000) : 'business-' + Math.floor(Math.random()*10000);

    const result = await db.query(
      'INSERT INTO businesses (id, name, phone, password, business_type, category, website_slug) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [businessId, name || 'My Business', phone, hashedPassword, businessType || 'General', category || 'Retail', slug]
    );

    const user = result.rows[0];
    const token = jwt.sign({ businessId: user.id, name: user.name, phone: user.phone }, JWT_SECRET);
    res.status(201).json({ token, business: user });
  } catch (err) {
    console.error('Register Error:', err);
    res.status(500).json({ error: 'Database error' });
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
      `UPDATE businesses SET name = $1, business_type = $2, website_slug = $3, gmb_location_id = $4 WHERE id = $5 RETURNING *`,
      [name, businessType, websiteSlug, req.body.gmbLocationId || null, req.user.businessId]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Failed to update onboarding info', details: err.message });
  }
});

// --- FULL BUSINESS PROFILE ENDPOINT ---
app.put('/api/businesses/profile', authenticateToken, async (req, res) => {
  const {
    name, address, email, gstin, category, businessType,
    state, district, city, pincode, invoiceFormat, invoiceTheme, certifications,
    logoUrl, signatureUrl
  } = req.body;
  try {
    await db.query(
      `UPDATE businesses SET
        name = COALESCE($1, name),
        address = COALESCE($2, address),
        email = COALESCE($3, email),
        gstin = COALESCE($4, gstin),
        category = COALESCE($5, category),
        business_type = COALESCE($6, business_type),
        state = COALESCE($7, state),
        district = COALESCE($8, district),
        city = COALESCE($9, city),
        pincode = COALESCE($10, pincode),
        invoice_format = COALESCE($11, invoice_format),
        invoice_theme = COALESCE($12, invoice_theme),
        certifications = COALESCE($13, certifications),
        logo_url = COALESCE($14, logo_url),
        signature_url = COALESCE($15, signature_url)
      WHERE id = $16`,
      [
        name, address, email, gstin, category, businessType,
        state, district, city, pincode, invoiceFormat, invoiceTheme,
        certifications ? JSON.stringify(certifications) : null,
        logoUrl, signatureUrl,
        req.user.businessId
      ]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('Profile Update Error:', err);
    res.status(500).json({ error: 'Failed to update profile', details: err.message });
  }
});

// --- PRODUCT DELETION ---
app.delete('/api/products/:id', authenticateToken, async (req, res) => {
  try {
    await db.query('DELETE FROM products WHERE id = $1 AND business_id = $2', [req.params.id, req.user.businessId]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete product' });
  }
});

app.post('/api/upload-logo', upload.single('logo'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  try {
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.headers['host'];
    const publicUrl = `${protocol}://${host}/uploads/logos/${req.file.filename}`;

    res.json({ success: true, url: publicUrl, filename: req.file.filename });
  } catch (err) {
    console.error('Logo Upload Error:', err);
    res.status(500).json({ error: 'Failed to save logo', details: err.message });
  }
});

// --- Profile ---
app.get('/api/profile', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM businesses WHERE id = $1', [req.user.businessId]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Business not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Fetch Profile Error:', err);
    res.status(500).json({ error: 'Database error' });
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
  const id = req.body.id;
  const name = req.body.name;
  const mrp = req.body.mrp || 0;
  const selling_price = req.body.selling_price || req.body.sellingPrice || req.body.price || 0;
  const codes = req.body.codes || [];
  const tax_rate = req.body.tax_rate || req.body.taxRate || 'exempt';
  const current_stock = req.body.current_stock ?? req.body.currentStock ?? req.body.initialStock ?? 0;
  const low_stock_level = req.body.low_stock_level ?? req.body.lowStockAlertLevel ?? 0;

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
      [id, req.user.businessId, name, mrp, selling_price, selling_price, JSON.stringify(codes), tax_rate, current_stock, low_stock_level]
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
  const { id, customer_name, customer_phone, total, payment_mode, invoice_type, lines } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO invoices (id, business_id, customer_name, customer_phone, total, payment_mode, invoice_type, lines) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
       ON CONFLICT (id) DO UPDATE SET
         customer_name = EXCLUDED.customer_name,
         total = EXCLUDED.total,
         payment_mode = EXCLUDED.payment_mode,
         invoice_type = EXCLUDED.invoice_type,
         lines = EXCLUDED.lines
       RETURNING *`,
      [id, req.user.businessId, customer_name, customer_phone, total, payment_mode, invoice_type || 'invoice', JSON.stringify(lines || [])]
    );
    
    io.to(req.user.businessId).emit('sync_event', { type: 'InvoiceRecord', action: 'insert', data: result.rows[0] });
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Save Invoice Error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --- PUBLIC INVOICE VIEWER (for QR Code Scanning) ---
app.get('/api/invoice/:id', async (req, res) => {
  try {
    const invResult = await db.query(
      `SELECT i.*, b.name as business_name, b.address as business_address, b.phone as business_phone,
              b.gstin, b.logo_url, b.certifications, b.invoice_theme
       FROM invoices i JOIN businesses b ON i.business_id = b.id
       WHERE i.id = $1`,
      [req.params.id]
    );
    if (invResult.rows.length === 0) return res.status(404).json({ error: 'Invoice not found' });
    res.json(invResult.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Online verifiable invoice HTML page
app.get('/invoice/:id', async (req, res) => {
  try {
    const invResult = await db.query(
      `SELECT i.*, b.name as business_name, b.address as business_address, b.phone as business_phone,
              b.gstin, b.logo_url, b.certifications, b.invoice_theme
       FROM invoices i JOIN businesses b ON i.business_id = b.id
       WHERE i.id = $1`,
      [req.params.id]
    );
    if (invResult.rows.length === 0) {
      return res.status(404).send('<h2>Invoice not found</h2>');
    }
    const inv = invResult.rows[0];
    const lines = (typeof inv.lines === 'string' ? JSON.parse(inv.lines) : inv.lines) || [];
    const certs = (typeof inv.certifications === 'string' ? JSON.parse(inv.certifications) : inv.certifications) || [];
    const theme = inv.invoice_theme || 'standard';
    const isQuotation = inv.invoice_type === 'quotation';
    const title = isQuotation ? 'QUOTATION / ESTIMATE' : 'TAX INVOICE';
    const themeColor = theme === 'modern' ? '#4f46e5' : theme === 'professional' ? '#0f172a' : '#1e293b';

    const linesHTML = lines.map((l, i) => {
      const name = l.name || (l.product && l.product.name) || (l.product_id ? `Product ${l.product_id}` : 'Item');
      const qty = l.quantity || l.qty || 1;
      const rate = l.unitPrice || l.unit_price || (l.finalAmount / qty) || 0;
      const amount = l.finalAmount || l.final_amount || (qty * rate) || 0;
      
      return `
      <tr>
        <td style="color:#64748b">${i + 1}</td>
        <td><span class="item-name">${name}</span></td>
        <td style="text-align:center">${qty}</td>
        <td style="text-align:right">₹${parseFloat(rate).toLocaleString('en-IN')}</td>
        <td style="text-align:right; font-weight:700">₹${parseFloat(amount).toLocaleString('en-IN')}</td>
      </tr>`;
    }).join('');

    const certsHTML = certs.map(c => `<span class="cert-badge">${c}</span>`).join('');

    const html = invoiceTemplate
      .replace(/{{title}}/g, title)
      .replace(/{{themeColor}}/g, themeColor)
      .replace(/{{businessName}}/g, inv.business_name)
      .replace(/{{businessAddress}}/g, inv.business_address || '')
      .replace(/{{businessPhone}}/g, inv.business_phone || '')
      .replace(/{{gstin}}/g, inv.gstin ? '| GSTIN: ' + inv.gstin : '')
      .replace(/{{customerName}}/g, inv.customer_name || 'Walk-in Customer')
      .replace(/{{customerPhone}}/g, inv.customer_phone || '')
      .replace(/{{invoiceId}}/g, inv.id)
      .replace(/{{date}}/g, new Date(inv.created_at).toLocaleDateString('en-IN', { day:'2-digit', month:'short', year:'numeric' }))
      .replace(/{{paymentMode}}/g, (inv.payment_mode || 'cash').toUpperCase())
      .replace(/{{linesHTML}}/g, linesHTML || '<tr><td colspan="5" style="text-align:center;color:#94a3b8">No items</td></tr>')
      .replace(/{{total}}/g, parseFloat(inv.total).toLocaleString('en-IN'))
      .replace(/{{certsHTML}}/g, certsHTML ? '<div class="certs">' + certsHTML + '</div>' : '');

    res.send(html);
  } catch (err) {
    console.error('Invoice View Error:', err);
    res.status(500).send('<h2>Something went wrong</h2>');
  }
});

const PORT = process.env.PORT || 3000;

async function runPatch() {
  try {
    // Patch Businesses table with all new columns
    await db.query(`
      ALTER TABLE businesses 
      ADD COLUMN IF NOT EXISTS business_type VARCHAR(100),
      ADD COLUMN IF NOT EXISTS website_slug VARCHAR(255) UNIQUE,
      ADD COLUMN IF NOT EXISTS category VARCHAR(100),
      ADD COLUMN IF NOT EXISTS logo_url VARCHAR(500),
      ADD COLUMN IF NOT EXISTS website_config JSONB DEFAULT '{}',
      ADD COLUMN IF NOT EXISTS gmb_location_id VARCHAR(255),
      ADD COLUMN IF NOT EXISTS address TEXT,
      ADD COLUMN IF NOT EXISTS email VARCHAR(255),
      ADD COLUMN IF NOT EXISTS gstin VARCHAR(50),
      ADD COLUMN IF NOT EXISTS state VARCHAR(100),
      ADD COLUMN IF NOT EXISTS district VARCHAR(100),
      ADD COLUMN IF NOT EXISTS city VARCHAR(100),
      ADD COLUMN IF NOT EXISTS pincode VARCHAR(20),
      ADD COLUMN IF NOT EXISTS invoice_format VARCHAR(20) DEFAULT 'POS',
      ADD COLUMN IF NOT EXISTS invoice_theme VARCHAR(30) DEFAULT 'standard',
      ADD COLUMN IF NOT EXISTS online_store_theme VARCHAR(30) DEFAULT 'modern',
      ADD COLUMN IF NOT EXISTS certifications JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS signature_url VARCHAR(500),
      ADD COLUMN IF NOT EXISTS password VARCHAR(255)
    `);

    // OTP-based auth can create users without passwords
    await db.query('ALTER TABLE businesses ALTER COLUMN password DROP NOT NULL');
    // Patch Products
    await db.query(`
      ALTER TABLE products 
      ADD COLUMN IF NOT EXISTS mrp DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS selling_price DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS discount_percent DECIMAL(5, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'General',
      ADD COLUMN IF NOT EXISTS image_url TEXT
    `);
    // Patch Invoices with new fields
    await db.query(`
      ALTER TABLE invoices
      ADD COLUMN IF NOT EXISTS invoice_type VARCHAR(30) DEFAULT 'invoice',
      ADD COLUMN IF NOT EXISTS lines JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(15,2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS customer_gstin VARCHAR(50),
      ADD COLUMN IF NOT EXISTS customer_email VARCHAR(255)
    `);
    // Populate missing website_slugs for existing users
    const usersWithoutSlugs = await db.query('SELECT id, name FROM businesses WHERE website_slug IS NULL');
    for (const user of usersWithoutSlugs.rows) {
      const slug = (user.name || 'business').toLowerCase().replace(/[^a-z0-9]/g, '-') + '-' + Math.floor(Math.random() * 10000);
      await db.query('UPDATE businesses SET website_slug = $1 WHERE id = $2', [slug, user.id]);
    }

    console.log('✅ Database Auto-Patched!');
  } catch (err) {
    console.error('Auto-Patch Error:', err);
  }
}

(async () => {
  await runPatch();
  server.listen(PORT, () => {
    console.log(`ERP Backend API & WebSockets running on port ${PORT}`);
  });
})();
